local QBCore = exports[Config.Core]:GetCoreObject()

local ActiveDispatchers = {}
local ActiveBodycams = {}
local PendingAutoDispatch = {}
local ActiveCalls = {}
local UnitLocations = {}
local AuthSessions = {}

local function hasJobInGroup(player, group)
    if not player or not player.PlayerData or not player.PlayerData.job then return false end
    local jobName = player.PlayerData.job.name
    local grade = player.PlayerData.job.grade.level or 0
    local cfg = Config.Jobs[group]
    if not cfg then return false end

    for _, name in ipairs(cfg.names) do
        if name == jobName and grade >= cfg.minGrade then
            return true
        end
    end

    return false
end

local function getRole(source)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return nil end
    if hasJobInGroup(player, 'Police') then return 'police' end
    if hasJobInGroup(player, 'EMS') then return 'ems' end
    return nil
end

local function getDispatchersOnline()
    local total = 0
    for src, _ in pairs(ActiveDispatchers) do
        if GetPlayerPing(src) > 0 then total = total + 1 else ActiveDispatchers[src] = nil end
    end
    return total
end

local function canUseDispatchConsole(src)
    local player = QBCore.Functions.GetPlayer(src)
    return hasJobInGroup(player, 'Dispatch')
end

local function canAccessInvestigations(src)
    return getRole(src) == 'police'
end

local function isSupervisor(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not player.PlayerData or not player.PlayerData.job then return false end
    local grade = player.PlayerData.job.grade.level or 0
    return hasJobInGroup(player, 'Police') and grade >= Config.Supervisor.minPoliceGrade
end

local function isAuthenticated(src)
    if not Config.MDTAuth.enabled then return true end
    local session = AuthSessions[src]
    if not session then return false end
    local ttl = Config.MDTAuth.sessionTimeoutMinutes * 60
    if os.time() - session.loginAt > ttl then
        AuthSessions[src] = nil
        return false
    end
    return true
end

local function sanitizeBodycams()
    for src, cam in pairs(ActiveBodycams) do
        if GetPlayerPing(src) <= 0 then ActiveBodycams[src] = nil else cam.playerName = GetPlayerName(src) end
    end
end

local function nextCaseNumber()
    return ('CASE-%s-%s'):format(os.date('%y%m%d'), math.random(1000, 9999))
end

local function nextEvidenceNumber()
    return ('EVD-%s-%s'):format(os.date('%y%m%d'), math.random(10000, 99999))
end

local function pushCallToJobs(callType, payload)
    local eventCfg = Config.AutoDispatch.events[callType]
    if not eventCfg then return end

    for _, id in ipairs(QBCore.Functions.GetPlayers()) do
        local target = QBCore.Functions.GetPlayer(id)
        if target and target.PlayerData and target.PlayerData.job then
            for _, job in ipairs(eventCfg.jobs) do
                if target.PlayerData.job.name == job then
                    TriggerClientEvent('rs_mdt:client:dispatchCall', id, payload)
                    break
                end
            end
        end
    end
end

local function sendDiscordCall(payload)
    if not Config.Discord.enabled or Config.Discord.webhook911 == '' then return end
    local embed = {
        title = ('911 Call - %s'):format(payload.type or 'Unknown'),
        description = payload.details or 'No details provided',
        color = 15105570,
        fields = {
            { name = 'Call ID', value = tostring(payload.id or 'N/A'), inline = true },
            { name = 'Source', value = payload.callerName or 'Unknown', inline = true },
            { name = 'Coords', value = payload.location and (('X: %.2f Y: %.2f Z: %.2f'):format(payload.location.x or 0.0, payload.location.y or 0.0, payload.location.z or 0.0)) or 'N/A', inline = false }
        }
    }

    PerformHttpRequest(Config.Discord.webhook911, function() end, 'POST', json.encode({
        username = Config.Discord.username,
        avatar_url = Config.Discord.avatar_url,
        embeds = { embed }
    }), { ['Content-Type'] = 'application/json' })
end

local function registerCall(callType, payload)
    ActiveCalls[payload.id] = payload
    sendDiscordCall(payload)

    if getDispatchersOnline() > 0 then
        TriggerClientEvent('rs_mdt:client:dispatcherPrompt', -1, payload)
    else
        local delay = Config.AutoDispatch.baseDelaySeconds
        delay = math.max(Config.AutoDispatch.minDelaySeconds, math.min(delay, Config.AutoDispatch.maxDelaySeconds))
        local ticket = ('%s:%s'):format(callType, os.time())
        PendingAutoDispatch[ticket] = true
        SetTimeout(delay * 1000, function()
            if not PendingAutoDispatch[ticket] then return end
            PendingAutoDispatch[ticket] = nil
            if getDispatchersOnline() == 0 then pushCallToJobs(callType, payload) end
        end)
    end
end

RegisterNetEvent('rs_mdt:server:setDispatchStatus', function(isOnDutyDispatch)
    if isOnDutyDispatch and canUseDispatchConsole(source) then ActiveDispatchers[source] = true else ActiveDispatchers[source] = nil end
end)

RegisterNetEvent('rs_mdt:server:setBodycamStatus', function(data)
    local src = source
    local role = getRole(src)
    if role ~= 'police' and role ~= 'ems' then return end

    if data and data.active and data.stream_url and data.stream_url ~= '' then
        local player = QBCore.Functions.GetPlayer(src)
        ActiveBodycams[src] = {
            source = src,
            citizenid = player.PlayerData.citizenid,
            role = role,
            stream_url = data.stream_url,
            callsign = data.callsign or '',
            playerName = GetPlayerName(src)
        }
    else
        ActiveBodycams[src] = nil
    end
end)

RegisterNetEvent('rs_mdt:server:updateUnitLocation', function(location)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not player.PlayerData or not player.PlayerData.job then return end
    local job = player.PlayerData.job.name
    if not hasJobInGroup(player, 'Police') and not hasJobInGroup(player, 'EMS') and not hasJobInGroup(player, 'Dispatch') then return end

    UnitLocations[src] = {
        source = src,
        playerName = GetPlayerName(src),
        callsign = player.PlayerData.metadata and player.PlayerData.metadata.callsign or '',
        job = job,
        x = location.x,
        y = location.y,
        z = location.z,
        heading = location.heading,
        lastUpdate = os.time()
    }
end)

RegisterNetEvent('rs_mdt:server:resolveCall', function(callId)
    if not canUseDispatchConsole(source) then return end
    ActiveCalls[callId] = nil
end)

RegisterNetEvent(Config.PhoneBridge.eventName, function(data)
    local src = source
    local callerName = src > 0 and GetPlayerName(src) or (data.callerName or 'Unknown Caller')
    local location = data.location
    if not location and src > 0 then
        local coords = GetEntityCoords(GetPlayerPed(src))
        location = { x = coords.x, y = coords.y, z = coords.z }
    end

    local payload = {
        id = ('CALL-%s'):format(math.random(1000, 9999)),
        type = data.callType or 'call911',
        location = location,
        details = data.message or data.details or '911 caller requested assistance',
        callerName = callerName,
        createdAt = os.time()
    }

    registerCall('call911', payload)
end)

AddEventHandler('playerDropped', function()
    ActiveDispatchers[source] = nil
    ActiveBodycams[source] = nil
    UnitLocations[source] = nil
    AuthSessions[source] = nil
end)

QBCore.Functions.CreateCallback('rs_mdt:server:login', function(source, cb, username, password)
    local role = getRole(source)
    if not role then cb({ ok = false, message = 'Not authorized role' }) return end

    local player = QBCore.Functions.GetPlayer(source)
    local cid = player.PlayerData.citizenid
    local row = MySQL.single.await('SELECT id, username FROM mdt_accounts WHERE citizenid = ? AND username = ? AND password_hash = SHA2(?, 256) AND active = 1', { cid, username, password })
    if not row then
        cb({ ok = false, message = 'Invalid MDT credentials' })
        return
    end

    AuthSessions[source] = { citizenid = cid, loginAt = os.time() }
    cb({ ok = true })
end)

QBCore.Functions.CreateCallback('rs_mdt:server:getBootstrap', function(source, cb)
    local role = getRole(source)
    if not role then cb({ allowed = false }) return end

    local player = QBCore.Functions.GetPlayer(source)
    local cid = player.PlayerData.citizenid
    local account = MySQL.single.await('SELECT id, username FROM mdt_accounts WHERE citizenid = ? AND active = 1', { cid })
    local requiresLogin = Config.MDTAuth.enabled and account ~= nil and not isAuthenticated(source)

    if requiresLogin then
        cb({ allowed = true, role = role, requiresLogin = true, hasAccount = true })
        return
    end

    if Config.MDTAuth.enabled and not account then
        cb({ allowed = true, role = role, requiresLogin = true, hasAccount = false })
        return
    end

    local warrants = MySQL.query.await('SELECT id, suspect_name, suspect_cid, charges, notes, status, created_at FROM mdt_warrants WHERE status = ? ORDER BY created_at DESC LIMIT 50', { 'active' })
    local bolos = MySQL.query.await('SELECT id, title, notes, vehicle_plate, status, created_at FROM mdt_bolos WHERE status = ? ORDER BY created_at DESC LIMIT 50', { 'active' })
    local emsCases = MySQL.query.await('SELECT id, patient_cid, summary, injury_type, severity, status, created_at FROM ems_cases ORDER BY created_at DESC LIMIT 50')
    local suspects = MySQL.query.await('SELECT id, suspect_cid, first_name, last_name, dob, photo_url, fingerprint_url, dna_profile, phone, address, parole_status, risk_level, notes, updated_at FROM mdt_suspects ORDER BY updated_at DESC LIMIT 100')
    local charges = MySQL.query.await('SELECT id, code, title, category, class, fine, jail_months, points, statute, notes FROM mdt_charges WHERE active = 1 ORDER BY category, code')
    local cases = MySQL.query.await('SELECT id, case_number, title, case_type, status, priority, summary, suspect_cid, assigned_unit, created_by, created_at FROM mdt_cases ORDER BY created_at DESC LIMIT 100')
    local reports = MySQL.query.await('SELECT id, case_id, report_type, title, narrative, findings, recommendations, created_by, created_at FROM mdt_reports ORDER BY created_at DESC LIMIT 100')
    local evidence = MySQL.query.await([[SELECT e.id, e.evidence_number, e.case_id, e.report_id, e.evidence_type, e.title, e.description, e.file_url, e.thumb_url, e.metadata_json, e.submitted_by, e.submitted_at, p.locker_code, p.shelf_slot, p.seal_number, p.court_status FROM mdt_evidence e LEFT JOIN mdt_physical_evidence p ON p.evidence_id = e.id ORDER BY e.submitted_at DESC LIMIT 120]])
    local profile = MySQL.single.await('SELECT callsign, rank_title, badge_image_url, profile_image_url FROM mdt_profiles WHERE citizenid = ?', { cid })
    local officers = MySQL.query.await([[SELECT p.citizenid, p.callsign, p.rank_title, p.badge_image_url, p.profile_image_url, c.charinfo FROM mdt_profiles p LEFT JOIN players c ON c.citizenid = p.citizenid ORDER BY p.rank_title ASC, p.callsign ASC LIMIT 200]])

    sanitizeBodycams()
    local bodycams, units, calls = {}, {}, {}
    for _, cam in pairs(ActiveBodycams) do bodycams[#bodycams + 1] = cam end
    for src, u in pairs(UnitLocations) do
        if GetPlayerPing(src) > 0 then units[#units + 1] = u else UnitLocations[src] = nil end
    end
    for _, c in pairs(ActiveCalls) do calls[#calls + 1] = c end

    cb({
        allowed = true,
        role = role,
        requiresLogin = false,
        hasAccount = account ~= nil,
        isSupervisor = isSupervisor(source),
        profile = profile,
        dispatchersOnline = getDispatchersOnline(),
        warrants = warrants,
        bolos = bolos,
        emsCases = emsCases,
        suspects = suspects,
        officers = officers,
        bodycams = bodycams,
        charges = charges,
        cases = cases,
        reports = reports,
        evidence = evidence,
        liveUnits = units,
        activeCalls = calls,
        mapBounds = Config.DispatchMap.worldBounds
    })
end)

RegisterNetEvent('rs_mdt:server:setMdtAccount', function(data)
    local src = source
    if not isSupervisor(src) then return end

    MySQL.query.await([[
        INSERT INTO mdt_accounts (citizenid, username, password_hash, created_by, active)
        VALUES (?, ?, SHA2(?, 256), ?, 1)
        ON DUPLICATE KEY UPDATE
            username = VALUES(username),
            password_hash = VALUES(password_hash),
            created_by = VALUES(created_by),
            active = 1
    ]], { data.citizenid, data.username, data.password, GetPlayerName(src) })
end)

RegisterNetEvent('rs_mdt:server:createWarrant', function(data)
    local src = source
    if getRole(src) ~= 'police' then return end
    MySQL.insert.await('INSERT INTO mdt_warrants (suspect_name, suspect_cid, charges, notes, created_by, status) VALUES (?, ?, ?, ?, ?, "active")', { data.suspect_name, data.suspect_cid, json.encode(data.charges or {}), data.notes, GetPlayerName(src) })
end)

RegisterNetEvent('rs_mdt:server:createEMSCase', function(data)
    local src = source
    if getRole(src) ~= 'ems' then return end
    MySQL.insert.await('INSERT INTO ems_cases (patient_cid, summary, injury_type, treatment, severity, created_by, status) VALUES (?, ?, ?, ?, ?, ?, "open")', { data.patient_cid, data.summary, data.injury_type, data.treatment, data.severity, GetPlayerName(src) })
end)

RegisterNetEvent('rs_mdt:server:saveSuspect', function(data)
    local src = source
    if getRole(src) ~= 'police' then return end
    MySQL.query.await([[INSERT INTO mdt_suspects (suspect_cid, first_name, last_name, dob, photo_url, fingerprint_url, dna_profile, phone, address, parole_status, risk_level, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE first_name = VALUES(first_name), last_name = VALUES(last_name), dob = VALUES(dob), photo_url = VALUES(photo_url), fingerprint_url = VALUES(fingerprint_url), dna_profile = VALUES(dna_profile), phone = VALUES(phone), address = VALUES(address), parole_status = VALUES(parole_status), risk_level = VALUES(risk_level), notes = VALUES(notes)]], { data.suspect_cid, data.first_name, data.last_name, data.dob, data.photo_url, data.fingerprint_url, data.dna_profile, data.phone, data.address, data.parole_status, data.risk_level, data.notes })
end)

RegisterNetEvent('rs_mdt:server:updateOfficer', function(data)
    local src = source
    if getRole(src) ~= 'police' then return end
    MySQL.query.await([[INSERT INTO mdt_profiles (citizenid, callsign, rank_title, badge_image_url, profile_image_url) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE callsign = VALUES(callsign), rank_title = VALUES(rank_title), badge_image_url = VALUES(badge_image_url), profile_image_url = VALUES(profile_image_url)]], { data.citizenid, data.callsign, data.rank_title, data.badge_image_url, data.profile_image_url })
end)

RegisterNetEvent('rs_mdt:server:addCharge', function(data)
    local src = source
    if not canAccessInvestigations(src) then return end
    MySQL.insert.await('INSERT INTO mdt_charges (code, title, category, class, fine, jail_months, points, statute, notes, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', { data.code, data.title, data.category, data.class, tonumber(data.fine) or 0, tonumber(data.jail_months) or 0, tonumber(data.points) or 0, data.statute, data.notes, GetPlayerName(src) })
end)

RegisterNetEvent('rs_mdt:server:createCase', function(data)
    local src = source
    if not canAccessInvestigations(src) then return end
    local caseId = MySQL.insert.await('INSERT INTO mdt_cases (case_number, title, case_type, status, priority, summary, suspect_cid, officer_cid, assigned_unit, tags, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', { nextCaseNumber(), data.title, data.case_type or 'criminal', data.status or 'open', data.priority or 'normal', data.summary, data.suspect_cid, data.officer_cid, data.assigned_unit, data.tags, GetPlayerName(src) })
    for _, selectedCharge in ipairs(data.charges or {}) do
        MySQL.insert.await('INSERT INTO mdt_case_charges (case_id, charge_id, charge_label, count, enhancement) VALUES (?, ?, ?, ?, ?)', { caseId, selectedCharge.id, selectedCharge.label or selectedCharge.title or 'Unknown Charge', tonumber(selectedCharge.count) or 1, selectedCharge.enhancement })
    end
end)

RegisterNetEvent('rs_mdt:server:createReport', function(data)
    local src = source
    if not canAccessInvestigations(src) then return end
    MySQL.insert.await('INSERT INTO mdt_reports (case_id, report_type, title, narrative, findings, recommendations, created_by) VALUES (?, ?, ?, ?, ?, ?, ?)', { tonumber(data.case_id), data.report_type or 'incident', data.title, data.narrative, data.findings, data.recommendations, GetPlayerName(src) })
end)

RegisterNetEvent('rs_mdt:server:addEvidence', function(data)
    local src = source
    if not canAccessInvestigations(src) then return end

    local evidenceId = MySQL.insert.await('INSERT INTO mdt_evidence (evidence_number, case_id, report_id, evidence_type, title, description, file_url, thumb_url, metadata_json, submitted_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', { nextEvidenceNumber(), tonumber(data.case_id), tonumber(data.report_id), data.evidence_type, data.title, data.description, data.file_url, data.thumb_url, data.metadata_json, GetPlayerName(src) })
    MySQL.insert.await('INSERT INTO mdt_evidence_chain (evidence_id, action_type, to_holder, notes) VALUES (?, "logged", ?, ?)', { evidenceId, data.initial_holder or GetPlayerName(src), 'Initial evidence upload' })

    if data.is_physical then
        MySQL.insert.await('INSERT INTO mdt_physical_evidence (evidence_id, locker_code, shelf_slot, seal_number, weight_grams, condition_note, court_status) VALUES (?, ?, ?, ?, ?, ?, ?)', { evidenceId, data.locker_code, data.shelf_slot, data.seal_number, tonumber(data.weight_grams), data.condition_note, data.court_status or 'stored' })
        MySQL.insert.await('INSERT INTO mdt_evidence_chain (evidence_id, action_type, from_holder, to_holder, notes) VALUES (?, "locker_intake", ?, ?, ?)', { evidenceId, GetPlayerName(src), data.locker_code, 'Physical evidence entered into locker' })
    end
end)

RegisterCommand('dispatchtest', function(source, args)
    local callType = args[1] or 'shotsfired'
    local coords = GetEntityCoords(GetPlayerPed(source))
    local payload = { id = ('CALL-%s'):format(math.random(1000, 9999)), type = callType, location = { x = coords.x, y = coords.y, z = coords.z }, details = args[2] or 'Automatic test call', callerName = GetPlayerName(source), createdAt = os.time() }
    registerCall(callType, payload)
end, true)

RegisterNetEvent('rs_mdt:server:submitManualDispatch', function(callType, payload)
    if not canUseDispatchConsole(source) then return end
    pushCallToJobs(callType, payload)
end)

local QBCore = exports[Config.Core]:GetCoreObject()

local ActiveDispatchers = {}
local ActiveBodycams = {}
local PendingAutoDispatch = {}

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
        if GetPlayerPing(src) > 0 then
            total = total + 1
        else
            ActiveDispatchers[src] = nil
        end
    end
    return total
end

local function canUseDispatchConsole(src)
    local player = QBCore.Functions.GetPlayer(src)
    return hasJobInGroup(player, 'Dispatch')
end

local function sanitizeBodycams()
    for src, cam in pairs(ActiveBodycams) do
        if GetPlayerPing(src) <= 0 then
            ActiveBodycams[src] = nil
        else
            cam.playerName = GetPlayerName(src)
        end
    end
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

local function scheduleAutoDispatch(callType, payload)
    if not Config.AutoDispatch.enabled then return end

    local dispatchers = getDispatchersOnline()
    if dispatchers > 0 then return end

    local delay = Config.AutoDispatch.baseDelaySeconds
    delay = delay + (dispatchers * Config.AutoDispatch.perDispatcherDelayBonus)
    delay = math.max(Config.AutoDispatch.minDelaySeconds, math.min(delay, Config.AutoDispatch.maxDelaySeconds))

    local ticket = ('%s:%s'):format(callType, os.time())
    PendingAutoDispatch[ticket] = true

    SetTimeout(delay * 1000, function()
        if not PendingAutoDispatch[ticket] then return end
        PendingAutoDispatch[ticket] = nil
        if getDispatchersOnline() == 0 then
            pushCallToJobs(callType, payload)
        end
    end)
end

RegisterNetEvent('rs_mdt:server:setDispatchStatus', function(isOnDutyDispatch)
    if isOnDutyDispatch and canUseDispatchConsole(source) then
        ActiveDispatchers[source] = true
    else
        ActiveDispatchers[source] = nil
    end
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

AddEventHandler('playerDropped', function()
    ActiveDispatchers[source] = nil
    ActiveBodycams[source] = nil
end)

QBCore.Functions.CreateCallback('rs_mdt:server:getBootstrap', function(source, cb)
    local role = getRole(source)
    if not role then
        cb({ allowed = false })
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    local cid = player.PlayerData.citizenid

    local warrants = MySQL.query.await('SELECT id, suspect_name, suspect_cid, charges, notes, status, created_at FROM mdt_warrants WHERE status = ? ORDER BY created_at DESC LIMIT 50', { 'active' })
    local bolos = MySQL.query.await('SELECT id, title, notes, vehicle_plate, status, created_at FROM mdt_bolos WHERE status = ? ORDER BY created_at DESC LIMIT 50', { 'active' })
    local emsCases = MySQL.query.await('SELECT id, patient_cid, summary, injury_type, severity, status, created_at FROM ems_cases ORDER BY created_at DESC LIMIT 50')
    local suspects = MySQL.query.await('SELECT id, suspect_cid, first_name, last_name, dob, photo_url, fingerprint_url, dna_profile, phone, address, parole_status, risk_level, notes, updated_at FROM mdt_suspects ORDER BY updated_at DESC LIMIT 100')
    local profile = MySQL.single.await('SELECT callsign, rank_title, badge_image_url, profile_image_url FROM mdt_profiles WHERE citizenid = ?', { cid })

    local officers = MySQL.query.await([[
        SELECT p.citizenid, p.callsign, p.rank_title, p.badge_image_url, p.profile_image_url,
               c.charinfo
        FROM mdt_profiles p
        LEFT JOIN players c ON c.citizenid = p.citizenid
        ORDER BY p.rank_title ASC, p.callsign ASC
        LIMIT 200
    ]])

    sanitizeBodycams()
    local bodycams = {}
    for _, cam in pairs(ActiveBodycams) do
        bodycams[#bodycams + 1] = cam
    end

    cb({
        allowed = true,
        role = role,
        profile = profile,
        dispatchersOnline = getDispatchersOnline(),
        warrants = warrants,
        bolos = bolos,
        emsCases = emsCases,
        suspects = suspects,
        officers = officers,
        bodycams = bodycams
    })
end)

RegisterNetEvent('rs_mdt:server:createWarrant', function(data)
    local src = source
    if getRole(src) ~= 'police' then return end

    MySQL.insert.await([[
        INSERT INTO mdt_warrants (suspect_name, suspect_cid, charges, notes, created_by, status)
        VALUES (?, ?, ?, ?, ?, 'active')
    ]], {
        data.suspect_name,
        data.suspect_cid,
        json.encode(data.charges or {}),
        data.notes,
        GetPlayerName(src)
    })
end)

RegisterNetEvent('rs_mdt:server:createEMSCase', function(data)
    local src = source
    if getRole(src) ~= 'ems' then return end

    MySQL.insert.await([[
        INSERT INTO ems_cases (patient_cid, summary, injury_type, treatment, severity, created_by, status)
        VALUES (?, ?, ?, ?, ?, ?, 'open')
    ]], {
        data.patient_cid,
        data.summary,
        data.injury_type,
        data.treatment,
        data.severity,
        GetPlayerName(src)
    })
end)

RegisterNetEvent('rs_mdt:server:saveSuspect', function(data)
    local src = source
    if getRole(src) ~= 'police' then return end

    MySQL.query.await([[
        INSERT INTO mdt_suspects
            (suspect_cid, first_name, last_name, dob, photo_url, fingerprint_url, dna_profile, phone, address, parole_status, risk_level, notes)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            first_name = VALUES(first_name),
            last_name = VALUES(last_name),
            dob = VALUES(dob),
            photo_url = VALUES(photo_url),
            fingerprint_url = VALUES(fingerprint_url),
            dna_profile = VALUES(dna_profile),
            phone = VALUES(phone),
            address = VALUES(address),
            parole_status = VALUES(parole_status),
            risk_level = VALUES(risk_level),
            notes = VALUES(notes)
    ]], {
        data.suspect_cid,
        data.first_name,
        data.last_name,
        data.dob,
        data.photo_url,
        data.fingerprint_url,
        data.dna_profile,
        data.phone,
        data.address,
        data.parole_status,
        data.risk_level,
        data.notes
    })
end)

RegisterNetEvent('rs_mdt:server:updateOfficer', function(data)
    local src = source
    if getRole(src) ~= 'police' then return end

    MySQL.query.await([[
        INSERT INTO mdt_profiles (citizenid, callsign, rank_title, badge_image_url, profile_image_url)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            callsign = VALUES(callsign),
            rank_title = VALUES(rank_title),
            badge_image_url = VALUES(badge_image_url),
            profile_image_url = VALUES(profile_image_url)
    ]], {
        data.citizenid,
        data.callsign,
        data.rank_title,
        data.badge_image_url,
        data.profile_image_url
    })
end)

RegisterCommand('dispatchtest', function(source, args)
    local callType = args[1] or 'shotsfired'
    local payload = {
        id = ('CALL-%s'):format(math.random(1000, 9999)),
        type = callType,
        location = GetEntityCoords(GetPlayerPed(source)),
        details = args[2] or 'Automatic test call',
        createdAt = os.time()
    }

    if getDispatchersOnline() > 0 then
        TriggerClientEvent('rs_mdt:client:dispatcherPrompt', -1, payload)
    else
        scheduleAutoDispatch(callType, payload)
    end
end, true)

RegisterNetEvent('rs_mdt:server:submitManualDispatch', function(callType, payload)
    if not canUseDispatchConsole(source) then return end
    pushCallToJobs(callType, payload)
end)

local QBCore = exports[Config.Core]:GetCoreObject()

local ActiveDispatchers = {}
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
    if dispatchers > 0 then
        return
    end

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

AddEventHandler('playerDropped', function()
    ActiveDispatchers[source] = nil
end)

QBCore.Functions.CreateCallback('rs_mdt:server:getBootstrap', function(source, cb)
    local role = getRole(source)
    if not role then
        cb({ allowed = false })
        return
    end

    local player = QBCore.Functions.GetPlayer(source)
    local cid = player.PlayerData.citizenid

    local warrants = MySQL.query.await('SELECT id, suspect_name, charges, status, created_at FROM mdt_warrants WHERE status = ? ORDER BY created_at DESC LIMIT 50', { 'active' })
    local bolos = MySQL.query.await('SELECT id, title, notes, vehicle_plate, status, created_at FROM mdt_bolos WHERE status = ? ORDER BY created_at DESC LIMIT 50', { 'active' })
    local emsCases = MySQL.query.await('SELECT id, patient_cid, summary, severity, status, created_at FROM ems_cases ORDER BY created_at DESC LIMIT 50')
    local profile = MySQL.single.await('SELECT callsign, rank_title FROM mdt_profiles WHERE citizenid = ?', { cid })

    cb({
        allowed = true,
        role = role,
        profile = profile,
        dispatchersOnline = getDispatchersOnline(),
        warrants = warrants,
        bolos = bolos,
        emsCases = emsCases
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

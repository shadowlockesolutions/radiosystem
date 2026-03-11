local QBCore = exports[Config.Core]:GetCoreObject()

local function openMDT()
    QBCore.Functions.TriggerCallback('rs_mdt:server:getBootstrap', function(data)
        if not data or not data.allowed then
            QBCore.Functions.Notify('Access denied to MDT.', 'error')
            return
        end

        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'open', payload = data })
    end)
end

RegisterCommand(Config.Command, function()
    openMDT()
end)

RegisterNUICallback('close', function(_, cb)
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('login', function(data, cb)
    QBCore.Functions.TriggerCallback('rs_mdt:server:login', function(result)
        cb(result)
    end, data.username, data.password)
end)

RegisterNUICallback('setMdtAccount', function(data, cb)
    TriggerServerEvent('rs_mdt:server:setMdtAccount', data)
    cb(true)
end)

RegisterNUICallback('setDispatchStatus', function(data, cb)
    TriggerServerEvent('rs_mdt:server:setDispatchStatus', data.active == true)
    cb(true)
end)

RegisterNUICallback('setBodycamStatus', function(data, cb)
    TriggerServerEvent('rs_mdt:server:setBodycamStatus', data)
    cb(true)
end)

RegisterNUICallback('createWarrant', function(data, cb)
    TriggerServerEvent('rs_mdt:server:createWarrant', data)
    cb(true)
end)

RegisterNUICallback('createEMSCase', function(data, cb)
    TriggerServerEvent('rs_mdt:server:createEMSCase', data)
    cb(true)
end)

RegisterNUICallback('saveSuspect', function(data, cb)
    TriggerServerEvent('rs_mdt:server:saveSuspect', data)
    cb(true)
end)

RegisterNUICallback('updateOfficer', function(data, cb)
    TriggerServerEvent('rs_mdt:server:updateOfficer', data)
    cb(true)
end)

RegisterNUICallback('addCharge', function(data, cb)
    TriggerServerEvent('rs_mdt:server:addCharge', data)
    cb(true)
end)

RegisterNUICallback('createCase', function(data, cb)
    TriggerServerEvent('rs_mdt:server:createCase', data)
    cb(true)
end)

RegisterNUICallback('createReport', function(data, cb)
    TriggerServerEvent('rs_mdt:server:createReport', data)
    cb(true)
end)

RegisterNUICallback('addEvidence', function(data, cb)
    TriggerServerEvent('rs_mdt:server:addEvidence', data)
    cb(true)
end)

RegisterNUICallback('resolveCall', function(data, cb)
    TriggerServerEvent('rs_mdt:server:resolveCall', data.callId)
    cb(true)
end)

RegisterNUICallback('manualDispatch', function(data, cb)
    TriggerServerEvent('rs_mdt:server:submitManualDispatch', data.callType, data.payload)
    cb(true)
end)

RegisterNUICallback('refresh', function(_, cb)
    QBCore.Functions.TriggerCallback('rs_mdt:server:getBootstrap', function(data)
        cb(data)
    end)
end)

CreateThread(function()
    while true do
        Wait(Config.DispatchMap.updateIntervalMs)
        local playerData = QBCore.Functions.GetPlayerData()
        if playerData and playerData.job and playerData.job.name then
            local job = playerData.job.name
            local police = (job == 'police' or job == 'sheriff' or job == 'statepolice' or job == 'dispatch')
            local ems = (job == 'ambulance' or job == 'ems')
            if police or ems then
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                TriggerServerEvent('rs_mdt:server:updateUnitLocation', {
                    x = coords.x,
                    y = coords.y,
                    z = coords.z,
                    heading = GetEntityHeading(ped)
                })
            end
        end
    end
end)

RegisterNetEvent('rs_mdt:client:dispatchCall', function(call)
    QBCore.Functions.Notify(('Dispatch: %s'):format(call.type), 'primary', 8000)
    SendNUIMessage({ action = 'dispatchCall', payload = call })
end)

RegisterNetEvent('rs_mdt:client:dispatcherPrompt', function(call)
    SendNUIMessage({ action = 'dispatcherPrompt', payload = call })
end)

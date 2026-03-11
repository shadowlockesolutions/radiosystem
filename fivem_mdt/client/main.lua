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

RegisterNUICallback('manualDispatch', function(data, cb)
    TriggerServerEvent('rs_mdt:server:submitManualDispatch', data.callType, data.payload)
    cb(true)
end)

RegisterNUICallback('refresh', function(_, cb)
    QBCore.Functions.TriggerCallback('rs_mdt:server:getBootstrap', function(data)
        cb(data)
    end)
end)

RegisterNetEvent('rs_mdt:client:dispatchCall', function(call)
    QBCore.Functions.Notify(('Dispatch: %s'):format(call.type), 'primary', 8000)
    SendNUIMessage({ action = 'dispatchCall', payload = call })
end)

RegisterNetEvent('rs_mdt:client:dispatcherPrompt', function(call)
    SendNUIMessage({ action = 'dispatcherPrompt', payload = call })
end)

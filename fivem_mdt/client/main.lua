local QBCore = exports[Config.Core]:GetCoreObject()
local uiOpen = false

local function openMDT()
    QBCore.Functions.TriggerCallback('rs_mdt:server:getBootstrap', function(data)
        if not data or not data.allowed then
            QBCore.Functions.Notify('Access denied to MDT.', 'error')
            return
        end

        uiOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'open',
            payload = data
        })
    end)
end

RegisterCommand(Config.Command, function()
    openMDT()
end)

RegisterNUICallback('close', function(_, cb)
    uiOpen = false
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNUICallback('setDispatchStatus', function(data, cb)
    TriggerServerEvent('rs_mdt:server:setDispatchStatus', data.active == true)
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

RegisterNUICallback('manualDispatch', function(data, cb)
    TriggerServerEvent('rs_mdt:server:submitManualDispatch', data.callType, data.payload)
    cb(true)
end)

RegisterNetEvent('rs_mdt:client:dispatchCall', function(call)
    QBCore.Functions.Notify(('Dispatch: %s'):format(call.type), 'primary', 8000)
    SendNUIMessage({ action = 'dispatchCall', payload = call })
end)

RegisterNetEvent('rs_mdt:client:dispatcherPrompt', function(call)
    SendNUIMessage({ action = 'dispatcherPrompt', payload = call })
end)

local isMarketOpen = false
local currentLocation = nil
local marketPeds = {}
local marketBlips = {}

-- Create market PEDs and blips
CreateThread(function()
    -- Wait for ox_target to be ready
    while GetResourceState('ox_target') ~= 'started' do
        Wait(100)
    end
    
    for i, location in ipairs(Config.Locations) do
        -- Create PED
        RequestModel(location.ped.model)
        while not HasModelLoaded(location.ped.model) do
            Wait(100)
        end
        
        local ped = CreatePed(4, location.ped.model, location.ped.coords.x, location.ped.coords.y, location.ped.coords.z - 1.0, location.ped.heading, false, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        
        marketPeds[i] = ped
        
        -- Add ox_target to PED
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'ns-market:openMarket',
                icon = 'fa-solid fa-store',
                label = 'Open Marketplace',
                onSelect = function()
                    currentLocation = location
                    TriggerServerEvent('ns-market:openMarket')
                end
            }
        })
        
        -- Create blip
        local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
        SetBlipSprite(blip, location.blip.sprite)
        SetBlipColour(blip, location.blip.color)
        SetBlipScale(blip, location.blip.scale)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(location.blip.label)
        EndTextCommandSetBlipName(blip)
        
        marketBlips[i] = blip
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        -- Remove ox_target from PEDs
        for _, ped in pairs(marketPeds) do
            if DoesEntityExist(ped) then
                exports.ox_target:removeLocalEntity(ped)
                DeleteEntity(ped)
            end
        end
        
        for _, blip in pairs(marketBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

-- Open marketplace UI
RegisterNetEvent('ns-market:openUI', function(listings, buyOrders, inventoryItems, allAvailableItems, blacklistedItems, pickups)
    if isMarketOpen then return end

    isMarketOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        listings = listings,
        buyOrders = buyOrders,
        inventoryItems = inventoryItems or {},
        allAvailableItems = allAvailableItems or {},
        blacklistedItems = blacklistedItems or {},
        pickups = pickups or {},
        playerId = GetPlayerServerId(PlayerId())
    })
end)

-- Receive pickups
RegisterNetEvent('ns-market:receivePickups', function(pickups)
    SendNUIMessage({
        action = 'pickups',
        pickups = pickups
    })
end)

-- Receive inventory items
RegisterNetEvent('ns-market:receiveInventoryItems', function(inventoryItems)
    SendNUIMessage({
        action = 'inventoryItems',
        inventoryItems = inventoryItems
    })
end)

-- Receive pickups
RegisterNetEvent('ns-market:receivePickups', function(pickups)
    SendNUIMessage({
        action = 'pickups',
        pickups = pickups
    })
end)

-- Refresh data
RegisterNetEvent('ns-market:refreshData', function(listings, buyOrders, pickups)
    SendNUIMessage({
        action = 'refresh',
        listings = listings,
        buyOrders = buyOrders,
        pickups = pickups
    })
end)

-- Close marketplace UI
RegisterNetEvent('ns-market:closeUI', function()
    if not isMarketOpen then return end
    
    isMarketOpen = false
    SetNuiFocus(false, false)
    
    -- Explicitly re-enable all controls immediately
    EnableAllControlActions(0)
    
    SendNUIMessage({
        action = 'close'
    })
end)

-- Refresh marketplace data
RegisterNetEvent('ns-market:refreshData', function(listings, buyOrders, pickups)
    if isMarketOpen then
        SendNUIMessage({
            action = 'refresh',
            listings = listings,
            buyOrders = buyOrders,
            pickups = pickups
        })
    end
end)

-- Receive history
RegisterNetEvent('ns-market:receiveHistory', function(history)
    SendNUIMessage({
        action = 'history',
        history = history
    })
end)

-- Notification
RegisterNetEvent('ns-market:notification', function(type, message)
    SendNUIMessage({
        action = 'notification',
        type = type,
        message = message
    })
end)

-- NUI Callbacks
RegisterNUICallback('close', function(data, cb)
    isMarketOpen = false
    SetNuiFocus(false, false)
    
    -- Explicitly re-enable all controls immediately
    EnableAllControlActions(0)
    
    cb('ok')
end)

RegisterNUICallback('listItem', function(data, cb)
    TriggerServerEvent('ns-market:listItem', data.item, data.quantity, data.price, data.metadata)
    cb('ok')
end)

RegisterNUICallback('purchaseItem', function(data, cb)
    TriggerServerEvent('ns-market:purchaseItem', data.listingId, data.quantity)
    cb('ok')
end)

RegisterNUICallback('createBuyOrder', function(data, cb)
    TriggerServerEvent('ns-market:createBuyOrder', data.item, data.quantity, data.price)
    cb('ok')
end)

RegisterNUICallback('cancelBuyOrder', function(data, cb)
    TriggerServerEvent('ns-market:cancelBuyOrder', data.orderId)
    cb('ok')
end)

RegisterNUICallback('fulfillBuyOrder', function(data, cb)
    TriggerServerEvent('ns-market:fulfillBuyOrder', data.orderId, data.quantity)
    cb('ok')
end)

RegisterNUICallback('cancelListing', function(data, cb)
    TriggerServerEvent('ns-market:cancelListing', data.listingId)
    cb('ok')
end)

RegisterNUICallback('getHistory', function(data, cb)
    TriggerServerEvent('ns-market:getHistory', data.filters)
    cb('ok')
end)

RegisterNUICallback('requestRefresh', function(data, cb)
    TriggerServerEvent('ns-market:requestRefresh')
    cb('ok')
end)

RegisterNUICallback('getInventoryItems', function(data, cb)
    TriggerServerEvent('ns-market:getInventoryItems')
    cb('ok')
end)

RegisterNUICallback('pickupOrder', function(data, cb)
    TriggerServerEvent('ns-market:pickupOrder', data.pickupId)
    cb('ok')
end)

RegisterNUICallback('getPickups', function(data, cb)
    TriggerServerEvent('ns-market:getPickups')
    cb('ok')
end)

-- Disable controls when UI is open
CreateThread(function()
    while true do
        if isMarketOpen then
            Wait(0)
            DisableControlAction(0, 1, true) -- LookLeftRight
            DisableControlAction(0, 2, true) -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 18, true) -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
        else
            -- Re-enable controls when UI is closed
            EnableControlAction(0, 1, true) -- LookLeftRight
            EnableControlAction(0, 2, true) -- LookUpDown
            EnableControlAction(0, 142, true) -- MeleeAttackAlternate
            EnableControlAction(0, 18, true) -- Enter
            EnableControlAction(0, 322, true) -- ESC
            EnableControlAction(0, 106, true) -- VehicleMouseControlOverride
            Wait(500)
        end
    end
end)


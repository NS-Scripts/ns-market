-- Cache for marketplace data
local cache = {
    listings = {},
    buyOrders = {},
    pickups = {},
    listingsLoaded = false,
    buyOrdersLoaded = false,
    pickupsLoaded = false
}

-- MySQL query helper
local function MySQLQuery(query, params, callback)
    if callback then
        MySQL.query(query, params, callback)
    else
        return MySQL.query.await(query, params)
    end
end

-- MySQL insert helper
local function MySQLInsert(query, params, callback)
    if callback then
        MySQL.insert(query, params, callback)
    else
        return MySQL.insert.await(query, params)
    end
end

-- MySQL update helper
local function MySQLUpdate(query, params, callback)
    if callback then
        MySQL.update(query, params, callback)
    else
        return MySQL.update.await(query, params)
    end
end

-- Load all listings from database
local function LoadListings(callback)
    MySQLQuery('SELECT * FROM ns_marketplace_listings ORDER BY id ASC', {}, function(result)
        if result then
            cache.listings = {}
            for _, row in ipairs(result) do
                local listing = {
                    id = row.id,
                    sellerCitizenid = row.seller_citizenid,
                    sellerFirstname = row.seller_firstname or '',
                    sellerLastname = row.seller_lastname or '',
                    sellerName = (row.seller_firstname or '') .. ' ' .. (row.seller_lastname or ''),
                    item = row.item,
                    quantity = row.quantity,
                    price = row.price,
                    totalPrice = row.total_price,
                    metadata = row.metadata and json.decode(row.metadata) or {},
                    created = row.created
                }
                table.insert(cache.listings, listing)
            end
            cache.listingsLoaded = true
            if callback then callback(cache.listings) end
        else
            cache.listings = {}
            cache.listingsLoaded = true
            if callback then callback({}) end
        end
    end)
end

-- Load all buy orders from database
local function LoadBuyOrders(callback)
    MySQLQuery('SELECT * FROM ns_marketplace_buy_orders ORDER BY id ASC', {}, function(result)
        if result then
            cache.buyOrders = {}
            for _, row in ipairs(result) do
                local order = {
                    id = row.id,
                    buyerCitizenid = row.buyer_citizenid,
                    buyerFirstname = row.buyer_firstname or '',
                    buyerLastname = row.buyer_lastname or '',
                    buyerName = (row.buyer_firstname or '') .. ' ' .. (row.buyer_lastname or ''),
                    item = row.item,
                    quantity = row.quantity,
                    price = row.price,
                    totalPrice = row.total_price,
                    created = row.created
                }
                table.insert(cache.buyOrders, order)
            end
            cache.buyOrdersLoaded = true
            if callback then callback(cache.buyOrders) end
        else
            cache.buyOrders = {}
            cache.buyOrdersLoaded = true
            if callback then callback({}) end
        end
    end)
end

-- Get all listings (from cache)
local function GetListings()
    if not cache.listingsLoaded then
        -- If not loaded yet, wait for it
        while not cache.listingsLoaded do
            Wait(10)
        end
    end
    return cache.listings
end

-- Get all buy orders (from cache)
local function GetBuyOrders()
    if not cache.buyOrdersLoaded then
        -- If not loaded yet, wait for it
        while not cache.buyOrdersLoaded do
            Wait(10)
        end
    end
    return cache.buyOrders
end

-- Load all pickups from database
local function LoadPickups(callback)
    MySQLQuery('SELECT * FROM ns_marketplace_pickups WHERE picked_up = 0 ORDER BY fulfilled_timestamp ASC', {}, function(result)
        if result then
            cache.pickups = {}
            for _, row in ipairs(result) do
                local pickup = {
                    id = row.id,
                    orderId = row.order_id,
                    buyerCitizenid = row.buyer_citizenid,
                    buyerFirstname = row.buyer_firstname or '',
                    buyerLastname = row.buyer_lastname or '',
                    buyerName = (row.buyer_firstname or '') .. ' ' .. (row.buyer_lastname or ''),
                    sellerCitizenid = row.seller_citizenid,
                    sellerFirstname = row.seller_firstname or '',
                    sellerLastname = row.seller_lastname or '',
                    sellerName = (row.seller_firstname or '') .. ' ' .. (row.seller_lastname or ''),
                    item = row.item,
                    quantity = row.quantity,
                    price = row.price,
                    totalPrice = row.total_price,
                    metadata = row.metadata and json.decode(row.metadata) or {},
                    fulfilledTimestamp = row.fulfilled_timestamp
                }
                table.insert(cache.pickups, pickup)
            end
            cache.pickupsLoaded = true
            if callback then callback(cache.pickups) end
        else
            cache.pickups = {}
            cache.pickupsLoaded = true
            if callback then callback({}) end
        end
    end)
end

-- Get all pickups (from cache)
local function GetPickups()
    if not cache.pickupsLoaded then
        -- If not loaded yet, wait for it
        while not cache.pickupsLoaded do
            Wait(10)
        end
    end
    return cache.pickups
end

-- Get player pickups
local function GetPlayerPickups(citizenid, callback)
    MySQLQuery('SELECT * FROM ns_marketplace_pickups WHERE buyer_citizenid = ? AND picked_up = 0 ORDER BY fulfilled_timestamp ASC', {citizenid}, function(result)
        if result then
            local pickups = {}
            for _, row in ipairs(result) do
                local pickup = {
                    id = row.id,
                    orderId = row.order_id,
                    buyerCitizenid = row.buyer_citizenid,
                    buyerFirstname = row.buyer_firstname or '',
                    buyerLastname = row.buyer_lastname or '',
                    buyerName = (row.buyer_firstname or '') .. ' ' .. (row.buyer_lastname or ''),
                    sellerCitizenid = row.seller_citizenid,
                    sellerFirstname = row.seller_firstname or '',
                    sellerLastname = row.seller_lastname or '',
                    sellerName = (row.seller_firstname or '') .. ' ' .. (row.seller_lastname or ''),
                    item = row.item,
                    quantity = row.quantity,
                    price = row.price,
                    totalPrice = row.total_price,
                    metadata = row.metadata and json.decode(row.metadata) or {},
                    fulfilledTimestamp = row.fulfilled_timestamp
                }
                table.insert(pickups, pickup)
            end
            if callback then callback(pickups) end
        else
            if callback then callback({}) end
        end
    end)
end

-- Add pickup
local function AddPickup(pickup, callback)
    local metadataJson = json.encode(pickup.metadata or {})
    local query = [[
        INSERT INTO ns_marketplace_pickups (order_id, buyer_citizenid, buyer_firstname, buyer_lastname, seller_citizenid, seller_firstname, seller_lastname, item, quantity, price, total_price, metadata, fulfilled_timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    MySQLInsert(query, {
        pickup.orderId,
        pickup.buyerCitizenid,
        pickup.buyerFirstname,
        pickup.buyerLastname,
        pickup.sellerCitizenid,
        pickup.sellerFirstname,
        pickup.sellerLastname,
        pickup.item,
        pickup.quantity,
        pickup.price,
        pickup.totalPrice,
        metadataJson,
        pickup.fulfilledTimestamp or os.time()
    }, function(insertId)
        if insertId then
            pickup.id = insertId
            pickup.buyerName = pickup.buyerFirstname .. ' ' .. pickup.buyerLastname
            pickup.sellerName = pickup.sellerFirstname .. ' ' .. pickup.sellerLastname
            table.insert(cache.pickups, pickup)
            if callback then callback(insertId) end
        else
            if callback then callback(nil) end
        end
    end)
end

-- Mark pickup as collected
local function MarkPickupCollected(id, callback)
    MySQLUpdate('UPDATE ns_marketplace_pickups SET picked_up = 1 WHERE id = ?', {id}, function(affectedRows)
        if affectedRows > 0 then
            -- Remove from cache
            for i, pickup in ipairs(cache.pickups) do
                if pickup.id == id then
                    table.remove(cache.pickups, i)
                    break
                end
            end
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    end)
end

-- Add listing
local function AddListing(listing, callback)
    local metadataJson = json.encode(listing.metadata or {})
    local query = [[
        INSERT INTO ns_marketplace_listings (seller_citizenid, seller_firstname, seller_lastname, item, quantity, price, total_price, metadata, created)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    MySQLInsert(query, {
        listing.sellerCitizenid,
        listing.sellerFirstname,
        listing.sellerLastname,
        listing.item,
        listing.quantity,
        listing.price,
        listing.totalPrice or (listing.price * listing.quantity),
        metadataJson,
        listing.created or os.time()
    }, function(insertId)
        if insertId then
            listing.id = insertId
            listing.created = listing.created or os.time()
            listing.sellerName = listing.sellerFirstname .. ' ' .. listing.sellerLastname
            table.insert(cache.listings, listing)
            if callback then callback(insertId) end
        else
            if callback then callback(nil) end
        end
    end)
end

-- Remove listing
local function RemoveListing(id, callback)
    MySQLUpdate('DELETE FROM ns_marketplace_listings WHERE id = ?', {id}, function(affectedRows)
        if affectedRows > 0 then
            -- Remove from cache
            for i, listing in ipairs(cache.listings) do
                if listing.id == id then
                    table.remove(cache.listings, i)
                    break
                end
            end
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    end)
end

-- Get listing by ID
local function GetListing(id)
    for _, listing in ipairs(cache.listings) do
        if listing.id == id then
            return listing
        end
    end
    return nil
end

-- Update listing
local function UpdateListing(id, updates, callback)
    local setParts = {}
    local params = {}
    
    if updates.quantity then
        table.insert(setParts, 'quantity = ?')
        table.insert(params, updates.quantity)
    end
    if updates.price then
        table.insert(setParts, 'price = ?')
        table.insert(params, updates.price)
    end
    if updates.totalPrice then
        table.insert(setParts, 'total_price = ?')
        table.insert(params, updates.totalPrice)
    end
    
    if #setParts == 0 then
        if callback then callback(false) end
        return
    end
    
    table.insert(params, id)
    local query = 'UPDATE ns_marketplace_listings SET ' .. table.concat(setParts, ', ') .. ' WHERE id = ?'
    
    MySQLUpdate(query, params, function(affectedRows)
        if affectedRows > 0 then
            -- Update cache
            for _, listing in ipairs(cache.listings) do
                if listing.id == id then
                    if updates.quantity then listing.quantity = updates.quantity end
                    if updates.price then listing.price = updates.price end
                    if updates.totalPrice then listing.totalPrice = updates.totalPrice end
                    break
                end
            end
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    end)
end

-- Add buy order
local function AddBuyOrder(order, callback)
    local query = [[
        INSERT INTO ns_marketplace_buy_orders (buyer_citizenid, buyer_firstname, buyer_lastname, item, quantity, price, total_price, created)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    MySQLInsert(query, {
        order.buyerCitizenid,
        order.buyerFirstname,
        order.buyerLastname,
        order.item,
        order.quantity,
        order.price,
        order.totalPrice or (order.price * order.quantity),
        order.created or os.time()
    }, function(insertId)
        if insertId then
            order.id = insertId
            order.created = order.created or os.time()
            order.buyerName = order.buyerFirstname .. ' ' .. order.buyerLastname
            table.insert(cache.buyOrders, order)
            if callback then callback(insertId) end
        else
            if callback then callback(nil) end
        end
    end)
end

-- Remove buy order
local function RemoveBuyOrder(id, callback)
    MySQLUpdate('DELETE FROM ns_marketplace_buy_orders WHERE id = ?', {id}, function(affectedRows)
        if affectedRows > 0 then
            -- Remove from cache
            for i, order in ipairs(cache.buyOrders) do
                if order.id == id then
                    table.remove(cache.buyOrders, i)
                    break
                end
            end
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    end)
end

-- Get buy order by ID
local function GetBuyOrder(id)
    for _, order in ipairs(cache.buyOrders) do
        if order.id == id then
            return order
        end
    end
    return nil
end

-- Update buy order
local function UpdateBuyOrder(id, updates, callback)
    local setParts = {}
    local params = {}
    
    if updates.quantity then
        table.insert(setParts, 'quantity = ?')
        table.insert(params, updates.quantity)
    end
    if updates.price then
        table.insert(setParts, 'price = ?')
        table.insert(params, updates.price)
    end
    if updates.totalPrice then
        table.insert(setParts, 'total_price = ?')
        table.insert(params, updates.totalPrice)
    end
    
    if #setParts == 0 then
        if callback then callback(false) end
        return
    end
    
    table.insert(params, id)
    local query = 'UPDATE ns_marketplace_buy_orders SET ' .. table.concat(setParts, ', ') .. ' WHERE id = ?'
    
    MySQLUpdate(query, params, function(affectedRows)
        if affectedRows > 0 then
            -- Update cache
            for _, order in ipairs(cache.buyOrders) do
                if order.id == id then
                    if updates.quantity then order.quantity = updates.quantity end
                    if updates.price then order.price = updates.price end
                    if updates.totalPrice then order.totalPrice = updates.totalPrice end
                    break
                end
            end
            if callback then callback(true) end
        else
            if callback then callback(false) end
        end
    end)
end

-- Add history entry
local function AddHistory(entry, callback)
    
    local query = [[
        INSERT INTO ns_marketplace_history 
        (type, listing_id, order_id, seller_citizenid, seller_firstname, seller_lastname, buyer_citizenid, buyer_firstname, buyer_lastname, item, quantity, price, total_price, fee, timestamp)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]]
    
    MySQLInsert(query, {
        entry.type,
        entry.listingId,
        entry.orderId,
        entry.sellerCitizenid,
        entry.sellerFirstname,
        entry.sellerLastname,
        entry.buyerCitizenid,
        entry.buyerFirstname,
        entry.buyerLastname,
        entry.item,
        entry.quantity,
        entry.price,
        entry.totalPrice,
        entry.fee,
        entry.timestamp or os.time()
    }, function(insertId)
        if callback then callback(insertId) end
    end)
end

-- Get history with filters
local function GetHistory(filters, callback)
    filters = filters or {}
    local whereParts = {}
    local params = {}
    
    if filters.type then
        table.insert(whereParts, 'type = ?')
        table.insert(params, filters.type)
    end
    
    if filters.item then
        table.insert(whereParts, 'item = ?')
        table.insert(params, filters.item)
    end
    
    if filters.player then
        table.insert(whereParts, '(seller_citizenid = ? OR buyer_citizenid = ?)')
        table.insert(params, filters.player)
        table.insert(params, filters.player)
    end
    
    if filters.startDate then
        table.insert(whereParts, 'timestamp >= ?')
        table.insert(params, filters.startDate)
    end
    
    if filters.endDate then
        table.insert(whereParts, 'timestamp <= ?')
        table.insert(params, filters.endDate)
    end
    
    local whereClause = #whereParts > 0 and ('WHERE ' .. table.concat(whereParts, ' AND ')) or ''
    local query = 'SELECT * FROM ns_marketplace_history ' .. whereClause .. ' ORDER BY timestamp DESC LIMIT 1000'
    
    MySQLQuery(query, params, function(result)
        if result then
            local history = {}
            for _, row in ipairs(result) do
                -- Build seller name from firstname and lastname
                local sellerName = ''
                if row.seller_firstname and row.seller_lastname then
                    sellerName = (row.seller_firstname or '') .. ' ' .. (row.seller_lastname or '')
                elseif row.seller_firstname then
                    sellerName = row.seller_firstname
                elseif row.seller_lastname then
                    sellerName = row.seller_lastname
                end
                -- Trim whitespace
                sellerName = string.gsub(sellerName, '^%s+', '')
                sellerName = string.gsub(sellerName, '%s+$', '')
                if sellerName == '' then
                    sellerName = 'Unknown'
                end
                
                -- Build buyer name from firstname and lastname
                local buyerName = ''
                local buyerFirst = row.buyer_firstname or ''
                local buyerLast = row.buyer_lastname or ''
                
                -- Combine first and last name, handling empty strings
                if buyerFirst ~= '' and buyerLast ~= '' then
                    buyerName = buyerFirst .. ' ' .. buyerLast
                elseif buyerFirst ~= '' then
                    buyerName = buyerFirst
                elseif buyerLast ~= '' then
                    buyerName = buyerLast
                end
                
                -- Trim whitespace
                buyerName = string.gsub(buyerName, '^%s+', '')
                buyerName = string.gsub(buyerName, '%s+$', '')
                if buyerName == '' then
                    buyerName = 'Unknown'
                end
                
                local entry = {
                    id = row.id,
                    type = row.type,
                    listingId = row.listing_id,
                    orderId = row.order_id,
                    sellerCitizenid = row.seller_citizenid,
                    sellerFirstname = row.seller_firstname or '',
                    sellerLastname = row.seller_lastname or '',
                    sellerName = sellerName,
                    buyerCitizenid = row.buyer_citizenid,
                    buyerFirstname = row.buyer_firstname or '',
                    buyerLastname = row.buyer_lastname or '',
                    buyerName = buyerName,
                    item = row.item,
                    quantity = row.quantity,
                    price = row.price,
                    totalPrice = row.total_price,
                    fee = row.fee,
                    timestamp = row.timestamp
                }
                table.insert(history, entry)
            end
            if callback then callback(history) end
        else
            if callback then callback({}) end
        end
    end)
end

-- Get player listings count
local function GetPlayerListingsCount(citizenid, callback)
    if callback then
        MySQLQuery('SELECT COUNT(*) as count FROM ns_marketplace_listings WHERE seller_citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                callback(result[1].count)
            else
                callback(0)
            end
        end)
    else
        local count = 0
        for _, listing in ipairs(cache.listings) do
            if listing.sellerCitizenid == citizenid then
                count = count + 1
            end
        end
        return count
    end
end

-- Get player buy orders count
local function GetPlayerBuyOrdersCount(citizenid, callback)
    if callback then
        MySQLQuery('SELECT COUNT(*) as count FROM ns_marketplace_buy_orders WHERE buyer_citizenid = ?', {citizenid}, function(result)
            if result and result[1] then
                callback(result[1].count)
            else
                callback(0)
            end
        end)
    else
        local count = 0
        for _, order in ipairs(cache.buyOrders) do
            if order.buyerCitizenid == citizenid then
                count = count + 1
            end
        end
        return count
    end
end

-- Helper function to check if item is blacklisted
local function IsItemBlacklisted(item)
    if not item or type(item) ~= 'string' then
        return false
    end
    
    -- Normalize item name for comparison (lowercase, but keep weapon_ prefix uppercase)
    local normalizedItem = item:lower()
    if normalizedItem:sub(1, 7) == 'weapon_' then
        normalizedItem = item:upper()
    end
    
    for _, blacklisted in ipairs(Config.BlacklistedItems) do
        local normalizedBlacklisted = blacklisted:lower()
        if normalizedBlacklisted:sub(1, 7) == 'weapon_' then
            normalizedBlacklisted = blacklisted:upper()
        end
        
        if normalizedItem == normalizedBlacklisted or item == blacklisted then
            return true
        end
    end
    return false
end

-- Helper function to check if item exists in ox_inventory
local function DoesItemExist(item)
    if not item or type(item) ~= 'string' then
        return false
    end
    
    if GetResourceState('ox_inventory') == 'started' then
        -- Try to get the item data from ox_inventory
        local success, itemData = pcall(function()
            return exports.ox_inventory:Items(item)
        end)
        
        if success and itemData then
            return true
        end
    end
    return false
end

-- Get player inventory (adjust based on your inventory system)
local function GetPlayerInventory(source)
    -- This is a placeholder - adjust based on your inventory system
    -- Common inventory exports: ox_inventory, qb-inventory, esx_inventory, etc.
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetInventory(source)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:GetInventory(source)
    elseif GetResourceState('esx_inventory') == 'started' then
        return exports.esx_inventory:GetInventory(source)
    else
        -- Fallback: return empty inventory structure
        return {}
    end
end

-- Add item to player inventory
local function AddItemToPlayer(source, item, quantity, metadata)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(source, item, quantity, metadata)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:AddItem(source, item, quantity, metadata)
    elseif GetResourceState('esx_inventory') == 'started' then
        return exports.esx_inventory:AddItem(source, item, quantity, metadata)
    else
        -- Fallback: trigger event for your inventory system
        TriggerClientEvent('ns-market:addItem', source, item, quantity, metadata)
        return true
    end
end

-- Remove item from player inventory
local function RemoveItemFromPlayer(source, item, quantity, metadata)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(source, item, quantity, metadata)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:RemoveItem(source, item, quantity, metadata)
    elseif GetResourceState('esx_inventory') == 'started' then
        return exports.esx_inventory:RemoveItem(source, item, quantity, metadata)
    else
        -- Fallback: trigger event for your inventory system
        TriggerClientEvent('ns-market:removeItem', source, item, quantity, metadata)
        return true
    end
end

-- Get player money (adjust based on your framework)
local function GetPlayerMoney(source)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetItemCount(source, 'money') or 0
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:GetMoney(source) or 0
    elseif GetResourceState('es_extended') == 'started' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer.getMoney() or 0
    else
        -- Fallback: trigger event for your money system
        return 0
    end
end

-- Add money to player
local function AddMoneyToPlayer(source, amount)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:AddItem(source, 'money', amount)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:AddMoney(source, amount)
    elseif GetResourceState('es_extended') == 'started' then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.addMoney(amount)
        return true
    else
        -- Fallback: trigger event for your money system
        TriggerClientEvent('ns-market:addMoney', source, amount)
        return true
    end
end

-- Remove money from player
local function RemoveMoneyFromPlayer(source, amount)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:RemoveItem(source, 'money', amount)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:RemoveMoney(source, amount)
    elseif GetResourceState('es_extended') == 'started' then
        local xPlayer = ESX.GetPlayerFromId(source)
        xPlayer.removeMoney(amount)
        return true
    else
        -- Fallback: trigger event for your money system
        TriggerClientEvent('ns-market:removeMoney', source, amount)
        return true
    end
end

-- Get player citizenid from Qbox
local function GetPlayerCitizenid(source)
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player and Player.PlayerData then
            return Player.PlayerData.citizenid
        end
    end
    return nil
end

-- Get player name (firstname + lastname) from Qbox
local function GetPlayerNameById(source)
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            local charinfo = Player.PlayerData.charinfo
            if charinfo.firstname and charinfo.lastname then
                return charinfo.firstname .. ' ' .. charinfo.lastname
            end
        end
    end
    -- Fallback to server name
    return GetPlayerName(source) or "Unknown"
end

-- Get player firstname from Qbox
local function GetPlayerFirstname(source)
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            return Player.PlayerData.charinfo.firstname or ''
        end
    end
    return ''
end

-- Get player lastname from Qbox
local function GetPlayerLastname(source)
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayer(source)
        if Player and Player.PlayerData and Player.PlayerData.charinfo then
            return Player.PlayerData.charinfo.lastname or ''
        end
    end
    return ''
end

-- Get player source from citizenid (for notifications)
local function GetPlayerSourceFromCitizenid(citizenid)
    if GetResourceState('qbx_core') == 'started' then
        local Player = exports.qbx_core:GetPlayerByCitizenId(citizenid)
        if Player then
            return Player.PlayerData.source
        end
    end
    return nil
end

-- Get all available items from ox_inventory (for label-to-name mapping)
local function GetAllAvailableItems()
    local allItems = {}
    
    if GetResourceState('ox_inventory') == 'started' then
        local success, itemList = pcall(function()
            return exports.ox_inventory:Items()
        end)
        
        if success and itemList then
            for itemName, itemData in pairs(itemList) do
                -- Skip blacklisted items
                if not IsItemBlacklisted(itemName) then
                    table.insert(allItems, {
                        name = itemName,
                        label = itemData.label or itemName
                    })
                end
            end
        end
    end
    
    return allItems
end

-- Get player inventory items for listing
local function GetPlayerInventoryItems(source)
    if GetResourceState('ox_inventory') == 'started' then
        local inventory = exports.ox_inventory:GetInventory(source)
        local items = {}
        
        if inventory and inventory.items then
            for _, item in pairs(inventory.items) do
                if item.count and item.count > 0 then
                    -- Skip blacklisted items
                    if not IsItemBlacklisted(item.name) then
                        table.insert(items, {
                            name = item.name,
                            label = item.label or item.name,
                            count = item.count,
                            metadata = item.metadata or {}
                        })
                    end
                end
            end
        end
        
        return items
    end
    return {}
end

-- Event: Open marketplace
RegisterNetEvent('ns-market:openMarket', function()
    local source = source
    -- Get player inventory items
    local inventoryItems = GetPlayerInventoryItems(source)
    -- Get all available items for label-to-name mapping
    local allAvailableItems = GetAllAvailableItems()
    
    -- Refresh cache before sending
    LoadListings(function(listings)
        LoadBuyOrders(function(buyOrders)
            -- Add seller server ID to listings for UI comparison
            for _, listing in ipairs(listings) do
                listing.seller = GetPlayerSourceFromCitizenid(listing.sellerCitizenid)
            end
            
            -- Add buyer server ID to buy orders for UI comparison
            for _, order in ipairs(buyOrders) do
                order.buyer = GetPlayerSourceFromCitizenid(order.buyerCitizenid)
            end
            
            TriggerClientEvent('ns-market:openUI', source, listings, buyOrders, inventoryItems, allAvailableItems, Config.BlacklistedItems)
        end)
    end)
end)

-- Event: Get player inventory items
RegisterNetEvent('ns-market:getInventoryItems', function()
    local source = source
    local inventoryItems = GetPlayerInventoryItems(source)
    TriggerClientEvent('ns-market:receiveInventoryItems', source, inventoryItems)
end)

-- Event: List item for sale
RegisterNetEvent('ns-market:listItem', function(item, quantity, price, metadata)
    local source = source
    
    -- Validation
    if IsItemBlacklisted(item) then
        TriggerClientEvent('ns-market:notification', source, 'error', 'This item cannot be listed on the marketplace')
        return
    end
    
    if price < Config.Settings.minPrice or price > Config.Settings.maxPrice then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Invalid price range')
        return
    end
    
    if quantity < 1 then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Invalid quantity')
        return
    end
    
    -- Get player citizenid
    local citizenid = GetPlayerCitizenid(source)
    if not citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    local playerListingsCount = GetPlayerListingsCount(citizenid)
    if playerListingsCount >= Config.Settings.maxListingsPerPlayer then
        TriggerClientEvent('ns-market:notification', source, 'error', 'You have reached the maximum number of listings')
        return
    end
    
    -- Check if player has item using ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        local hasItem = exports.ox_inventory:GetItemCount(source, item) or 0
        if hasItem < quantity then
            TriggerClientEvent('ns-market:notification', source, 'error', 'You do not have enough of this item')
            return
        end
        
        -- Get item metadata if needed
        local inventory = exports.ox_inventory:GetInventory(source)
        local itemData = nil
        if inventory and inventory.items then
            for _, invItem in pairs(inventory.items) do
                if invItem.name == item and invItem.count >= quantity then
                    itemData = invItem
                    break
                end
            end
        end
        
        metadata = itemData and itemData.metadata or metadata or {}
    else
        TriggerClientEvent('ns-market:notification', source, 'error', 'Inventory system not available')
        return
    end
    
    -- Remove item from player using ox_inventory
    local removed = false
    if GetResourceState('ox_inventory') == 'started' then
        removed = exports.ox_inventory:RemoveItem(source, item, quantity, metadata)
    else
        removed = RemoveItemFromPlayer(source, item, quantity, metadata)
    end
    
    if removed then
        -- Get player info
        local citizenid = GetPlayerCitizenid(source)
        local firstname = GetPlayerFirstname(source)
        local lastname = GetPlayerLastname(source)
        
        if not citizenid then
            -- Return item if we can't get citizenid
            exports.ox_inventory:AddItem(source, item, quantity, metadata)
            TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
            return
        end
        
        -- Add listing
        local listing = {
            sellerCitizenid = citizenid,
            sellerFirstname = firstname,
            sellerLastname = lastname,
            item = item,
            quantity = quantity,
            price = price,
            metadata = metadata or {},
            totalPrice = price * quantity
        }
        
        AddListing(listing, function(listingId)
            if listingId then
                -- Add to history
                AddHistory({
                    type = 'listing',
                    listingId = listingId,
                    sellerCitizenid = citizenid,
                    sellerFirstname = firstname,
                    sellerLastname = lastname,
                    item = item,
                    quantity = quantity,
                    price = price,
                    timestamp = os.time()
                })
                
                TriggerClientEvent('ns-market:notification', source, 'success', 'Item listed successfully')
                TriggerClientEvent('ns-market:refreshData', source)
            else
                -- Return item if listing failed
                AddItemToPlayer(source, item, quantity, metadata)
                TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to create listing')
            end
        end)
    else
        TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to remove item from inventory')
    end
end)

-- Event: Purchase item
RegisterNetEvent('ns-market:purchaseItem', function(listingId, quantity)
    local source = source
    local listing = GetListing(listingId)
    
    if not listing then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Listing not found')
        return
    end
    
    -- Get buyer citizenid
    local buyerCitizenid = GetPlayerCitizenid(source)
    if not buyerCitizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    if listing.sellerCitizenid == buyerCitizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'You cannot purchase your own listing')
        return
    end
    
    if quantity > listing.quantity then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Not enough quantity available')
        return
    end
    
    local totalPrice = listing.price * quantity
    local fee = math.floor(totalPrice * (Config.Settings.transactionFeePercent / 100))
    local sellerAmount = totalPrice - fee
    
    -- Check if player has enough money
    if GetPlayerMoney(source) < totalPrice then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Insufficient funds')
        return
    end
    
    -- Get buyer info
    local buyerCitizenid = GetPlayerCitizenid(source)
    local buyerFirstname = GetPlayerFirstname(source)
    local buyerLastname = GetPlayerLastname(source)
    
    if not buyerCitizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    -- Remove money from buyer
    if RemoveMoneyFromPlayer(source, totalPrice) then
        -- Get seller source for payment
        local sellerSource = GetPlayerSourceFromCitizenid(listing.sellerCitizenid)
        if sellerSource then
            AddMoneyToPlayer(sellerSource, sellerAmount)
        end
        
        -- Add item to buyer using ox_inventory
        local metadata = listing.metadata or {}
        local added = false
        if GetResourceState('ox_inventory') == 'started' then
            added = exports.ox_inventory:AddItem(source, listing.item, quantity, metadata)
        else
            added = AddItemToPlayer(source, listing.item, quantity, metadata)
        end
        
        if added then
            -- Update or remove listing
            if quantity == listing.quantity then
                -- Remove entire listing
                RemoveListing(listingId, function(success)
                    if success then
                        -- Add to history
                        AddHistory({
                            type = 'purchase',
                            listingId = listingId,
                            sellerCitizenid = listing.sellerCitizenid,
                            sellerFirstname = listing.sellerFirstname,
                            sellerLastname = listing.sellerLastname,
                            buyerCitizenid = buyerCitizenid,
                            buyerFirstname = buyerFirstname,
                            buyerLastname = buyerLastname,
                            item = listing.item,
                            quantity = quantity,
                            price = listing.price,
                            totalPrice = totalPrice,
                            fee = fee,
                            timestamp = os.time()
                        })
                    end
                end)
            else
                -- Update listing quantity
                listing.quantity = listing.quantity - quantity
                UpdateListing(listingId, {
                    quantity = listing.quantity,
                    totalPrice = listing.price * listing.quantity
                }, function(success)
                    if success then
                        -- Add to history
                        AddHistory({
                            type = 'purchase',
                            listingId = listingId,
                            sellerCitizenid = listing.sellerCitizenid,
                            sellerFirstname = listing.sellerFirstname,
                            sellerLastname = listing.sellerLastname,
                            buyerCitizenid = buyerCitizenid,
                            buyerFirstname = buyerFirstname,
                            buyerLastname = buyerLastname,
                            item = listing.item,
                            quantity = quantity,
                            price = listing.price,
                            totalPrice = totalPrice,
                            fee = fee,
                            timestamp = os.time()
                        })
                    end
                end)
            end
            
            TriggerClientEvent('ns-market:notification', source, 'success', 'Item purchased successfully')
            -- Notify seller if online
            if sellerSource then
                TriggerClientEvent('ns-market:notification', sellerSource, 'info', 'Your item was sold')
                TriggerClientEvent('ns-market:refreshData', sellerSource)
            end
            TriggerClientEvent('ns-market:refreshData', source)
        else
            -- Refund money if item add failed
            AddMoneyToPlayer(source, totalPrice)
            if sellerSource then
                RemoveMoneyFromPlayer(sellerSource, sellerAmount)
            end
            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to add item to inventory')
        end
    else
        TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to process payment')
    end
end)

-- Event: Cancel listing
RegisterNetEvent('ns-market:cancelListing', function(listingId)
    local source = source
    local listing = GetListing(listingId)
    
    if not listing then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Listing not found')
        return
    end
    
    -- Get player citizenid
    local citizenid = GetPlayerCitizenid(source)
    if not citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    if listing.sellerCitizenid ~= citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'You cannot cancel this listing')
        return
    end
    
    -- Return item to player
    if GetResourceState('ox_inventory') == 'started' then
        local added = exports.ox_inventory:AddItem(source, listing.item, listing.quantity, listing.metadata or {})
        if not added then
            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to return item to inventory')
            return
        end
    else
        if not AddItemToPlayer(source, listing.item, listing.quantity, listing.metadata or {}) then
            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to return item to inventory')
            return
        end
    end
    
    -- Get player info (use listing's seller name as fallback)
    local firstname = GetPlayerFirstname(source)
    local lastname = GetPlayerLastname(source)
    
    -- Fallback to listing's seller name if current retrieval fails
    if (firstname == '' or not firstname) and listing.sellerFirstname then
        firstname = listing.sellerFirstname
    end
    if (lastname == '' or not lastname) and listing.sellerLastname then
        lastname = listing.sellerLastname
    end
    
    -- Remove listing
    RemoveListing(listingId, function(success)
        if success then
            -- Add to history
            AddHistory({
                type = 'listingCancel',
                listingId = listingId,
                sellerCitizenid = citizenid,
                sellerFirstname = firstname,
                sellerLastname = lastname,
                item = listing.item,
                quantity = listing.quantity,
                price = listing.price,
                timestamp = os.time()
            })
            
            TriggerClientEvent('ns-market:notification', source, 'success', 'Listing cancelled successfully')
            TriggerClientEvent('ns-market:refreshData', source)
        else
            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to cancel listing')
        end
    end)
end)

-- Event: Create buy order
RegisterNetEvent('ns-market:createBuyOrder', function(item, quantity, price)
    local source = source
    
    -- Validation
    if not item or item == '' then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Please enter an item name')
        return
    end
    
    -- Check if item exists in ox_inventory
    if not DoesItemExist(item) then
        TriggerClientEvent('ns-market:notification', source, 'error', 'This item does not exist in the inventory system')
        return
    end
    
    if IsItemBlacklisted(item) then
        TriggerClientEvent('ns-market:notification', source, 'error', 'This item cannot be ordered on the marketplace')
        return
    end
    
    if price < Config.Settings.minPrice or price > Config.Settings.maxPrice then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Invalid price range')
        return
    end
    
    if quantity < 1 then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Invalid quantity')
        return
    end
    
    -- Get player citizenid
    local citizenid = GetPlayerCitizenid(source)
    if not citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    local playerBuyOrdersCount = GetPlayerBuyOrdersCount(citizenid)
    if playerBuyOrdersCount >= Config.Settings.maxBuyOrdersPerPlayer then
        TriggerClientEvent('ns-market:notification', source, 'error', 'You have reached the maximum number of buy orders')
        return
    end
    
    local totalPrice = price * quantity
    
    -- Check if player has enough money
    if GetPlayerMoney(source) < totalPrice then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Insufficient funds')
        return
    end
    
    -- Get player info
    local firstname = GetPlayerFirstname(source)
    local lastname = GetPlayerLastname(source)
    
    -- Reserve money (remove from player)
    if RemoveMoneyFromPlayer(source, totalPrice) then
        -- Add buy order
        local order = {
            buyerCitizenid = citizenid,
            buyerFirstname = firstname,
            buyerLastname = lastname,
            item = item,
            quantity = quantity,
            price = price,
            totalPrice = totalPrice
        }
        
        AddBuyOrder(order, function(orderId)
            if orderId then
                -- Add to history
                AddHistory({
                    type = 'buyOrder',
                    orderId = orderId,
                    buyerCitizenid = citizenid,
                    buyerFirstname = firstname,
                    buyerLastname = lastname,
                    item = item,
                    quantity = quantity,
                    price = price,
                    timestamp = os.time()
                })
                
                TriggerClientEvent('ns-market:notification', source, 'success', 'Buy order created successfully')
                TriggerClientEvent('ns-market:refreshData', source)
            else
                -- Refund money if order creation failed
                AddMoneyToPlayer(source, totalPrice)
                TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to create buy order')
            end
        end)
    else
        TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to reserve funds')
    end
end)

-- Event: Cancel buy order
RegisterNetEvent('ns-market:cancelBuyOrder', function(orderId)
    local source = source
    local order = GetBuyOrder(orderId)
    
    if not order then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Buy order not found')
        return
    end
    
    -- Get player citizenid
    local citizenid = GetPlayerCitizenid(source)
    if not citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    if order.buyerCitizenid ~= citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'You cannot cancel this buy order')
        return
    end
    
    -- Refund money
    AddMoneyToPlayer(source, order.totalPrice)
    
    -- Get player info (use order's buyer name as fallback)
    local firstname = GetPlayerFirstname(source)
    local lastname = GetPlayerLastname(source)
    
    -- Fallback to order's buyer name if current retrieval fails
    if (firstname == '' or not firstname) and order.buyerFirstname then
        firstname = order.buyerFirstname
    end
    if (lastname == '' or not lastname) and order.buyerLastname then
        lastname = order.buyerLastname
    end
    
    -- Remove buy order
    RemoveBuyOrder(orderId, function(success)
        if success then
            -- Add to history
            AddHistory({
                type = 'buyOrderCancel',
                orderId = orderId,
                buyerCitizenid = citizenid,
                buyerFirstname = firstname,
                buyerLastname = lastname,
                item = order.item,
                quantity = order.quantity,
                price = order.price,
                timestamp = os.time()
            })
        end
    end)
    
    TriggerClientEvent('ns-market:notification', source, 'success', 'Buy order cancelled')
    TriggerClientEvent('ns-market:refreshData', source)
end)

-- Event: Fulfill buy order
RegisterNetEvent('ns-market:fulfillBuyOrder', function(orderId, quantity)
    local source = source
    local order = GetBuyOrder(orderId)
    
    if not order then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Buy order not found')
        return
    end
    
    -- Get seller citizenid
    local sellerCitizenid = GetPlayerCitizenid(source)
    if not sellerCitizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    if order.buyerCitizenid == sellerCitizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'You cannot fulfill your own buy order')
        return
    end
    
    if quantity > order.quantity then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Invalid quantity')
        return
    end
    
    -- Check if player has item using ox_inventory
    if GetResourceState('ox_inventory') == 'started' then
        local hasItem = exports.ox_inventory:GetItemCount(source, order.item) or 0
        if hasItem < quantity then
            TriggerClientEvent('ns-market:notification', source, 'error', 'You do not have enough of this item')
            return
        end
        
        -- Get item metadata
        local inventory = exports.ox_inventory:GetInventory(source)
        local itemData = nil
        if inventory and inventory.items then
            for _, invItem in pairs(inventory.items) do
                if invItem.name == order.item and invItem.count >= quantity then
                    itemData = invItem
                    break
                end
            end
        end
        
        local metadata = itemData and itemData.metadata or {}
        
        -- Remove item from seller
        local removed = exports.ox_inventory:RemoveItem(source, order.item, quantity, metadata)
        if removed then
            -- Get seller info
            local sellerFirstname = GetPlayerFirstname(source)
            local sellerLastname = GetPlayerLastname(source)
            
            -- Store item in pickup system instead of giving directly
            local totalPrice = order.price * quantity
            local fee = math.floor(totalPrice * (Config.Settings.transactionFeePercent / 100))
            local sellerAmount = totalPrice - fee
            
            -- Pay seller immediately
            AddMoneyToPlayer(source, sellerAmount)
            
            -- Create pickup entry
            local pickup = {
                orderId = orderId,
                buyerCitizenid = order.buyerCitizenid,
                buyerFirstname = order.buyerFirstname,
                buyerLastname = order.buyerLastname,
                sellerCitizenid = sellerCitizenid,
                sellerFirstname = sellerFirstname,
                sellerLastname = sellerLastname,
                item = order.item,
                quantity = quantity,
                price = order.price,
                totalPrice = totalPrice,
                metadata = metadata,
                fulfilledTimestamp = os.time()
            }
            
            AddPickup(pickup, function(pickupId)
                if pickupId then
                    -- Update or remove buy order
                    if quantity == order.quantity then
                        -- Remove entire buy order
                        RemoveBuyOrder(orderId, function(success)
                            if success then
                                -- Add to history
                                AddHistory({
                                    type = 'fulfill',
                                    orderId = orderId,
                                    sellerCitizenid = sellerCitizenid,
                                    sellerFirstname = sellerFirstname,
                                    sellerLastname = sellerLastname,
                                    buyerCitizenid = order.buyerCitizenid,
                                    buyerFirstname = order.buyerFirstname,
                                    buyerLastname = order.buyerLastname,
                                    item = order.item,
                                    quantity = quantity,
                                    price = order.price,
                                    totalPrice = totalPrice,
                                    fee = fee,
                                    timestamp = os.time()
                                })
                            end
                        end)
                    else
                        -- Update buy order
                        order.quantity = order.quantity - quantity
                        order.totalPrice = order.totalPrice - totalPrice
                        UpdateBuyOrder(orderId, {
                            quantity = order.quantity,
                            totalPrice = order.totalPrice
                        }, function(success)
                            if success then
                                -- Add to history
                                AddHistory({
                                    type = 'fulfill',
                                    orderId = orderId,
                                    sellerCitizenid = sellerCitizenid,
                                    sellerFirstname = sellerFirstname,
                                    sellerLastname = sellerLastname,
                                    buyerCitizenid = order.buyerCitizenid,
                                    buyerFirstname = order.buyerFirstname,
                                    buyerLastname = order.buyerLastname,
                                    item = order.item,
                                    quantity = quantity,
                                    price = order.price,
                                    totalPrice = totalPrice,
                                    fee = fee,
                                    timestamp = os.time()
                                })
                            end
                        end)
                    end
                    
                    TriggerClientEvent('ns-market:notification', source, 'success', 'Buy order fulfilled successfully. Buyer can pick up at the marketplace.')
                    -- Notify buyer if online
                    local buyerSource = GetPlayerSourceFromCitizenid(order.buyerCitizenid)
                    if buyerSource then
                        TriggerClientEvent('ns-market:notification', buyerSource, 'info', 'Your buy order was fulfilled! Pick it up at the marketplace.')
                        TriggerClientEvent('ns-market:refreshData', buyerSource)
                    end
                    TriggerClientEvent('ns-market:refreshData', source)
                else
                    -- Return item if pickup creation failed
                    exports.ox_inventory:AddItem(source, order.item, quantity, metadata)
                    RemoveMoneyFromPlayer(source, sellerAmount)
                    TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to create pickup')
                end
            end)
        else
            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to remove item from inventory')
        end
    else
        TriggerClientEvent('ns-market:notification', source, 'error', 'Inventory system not available')
        return
    end
end)

-- Event: Cancel listing (duplicate - already updated above)

-- Event: Pickup fulfilled order
RegisterNetEvent('ns-market:pickupOrder', function(pickupId)
    local source = source
    
    -- Get player citizenid
    local citizenid = GetPlayerCitizenid(source)
    if not citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'Unable to get player data')
        return
    end
    
    -- Find pickup
    local pickup = nil
    for _, p in ipairs(cache.pickups) do
        if p.id == pickupId then
            pickup = p
            break
        end
    end
    
    if not pickup then
        -- Try loading from database
        MySQLQuery('SELECT * FROM ns_marketplace_pickups WHERE id = ? AND picked_up = 0', {pickupId}, function(result)
            if result and result[1] then
                local row = result[1]
                if row.buyer_citizenid == citizenid then
                    -- Add item to player
                    local metadata = row.metadata and json.decode(row.metadata) or {}
                    if GetResourceState('ox_inventory') == 'started' then
                        local added = exports.ox_inventory:AddItem(source, row.item, row.quantity, metadata)
                        if added then
                            -- Mark as collected
                            MarkPickupCollected(pickupId, function(success)
                                if success then
                                    TriggerClientEvent('ns-market:notification', source, 'success', 'Order picked up successfully')
                                    TriggerClientEvent('ns-market:refreshData', source)
                                end
                            end)
                        else
                            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to add item to inventory')
                        end
                    else
                        TriggerClientEvent('ns-market:notification', source, 'error', 'Inventory system not available')
                    end
                else
                    TriggerClientEvent('ns-market:notification', source, 'error', 'This pickup does not belong to you')
                end
            else
                TriggerClientEvent('ns-market:notification', source, 'error', 'Pickup not found')
            end
        end)
        return
    end
    
    -- Verify ownership
    if pickup.buyerCitizenid ~= citizenid then
        TriggerClientEvent('ns-market:notification', source, 'error', 'This pickup does not belong to you')
        return
    end
    
    -- Add item to player
    if GetResourceState('ox_inventory') == 'started' then
        local added = exports.ox_inventory:AddItem(source, pickup.item, pickup.quantity, pickup.metadata)
        if added then
            -- Mark as collected
            MarkPickupCollected(pickupId, function(success)
                if success then
                    TriggerClientEvent('ns-market:notification', source, 'success', 'Order picked up successfully')
                    TriggerClientEvent('ns-market:refreshData', source)
                end
            end)
        else
            TriggerClientEvent('ns-market:notification', source, 'error', 'Failed to add item to inventory')
        end
    else
        TriggerClientEvent('ns-market:notification', source, 'error', 'Inventory system not available')
    end
end)

-- Event: Get player pickups
RegisterNetEvent('ns-market:getPickups', function()
    local source = source
    local citizenid = GetPlayerCitizenid(source)
    if citizenid then
        GetPlayerPickups(citizenid, function(pickups)
            TriggerClientEvent('ns-market:receivePickups', source, pickups)
        end)
    end
end)

-- Event: Get history
RegisterNetEvent('ns-market:getHistory', function(filters)
    local source = source
    GetHistory(filters, function(history)
        TriggerClientEvent('ns-market:receiveHistory', source, history)
    end)
end)

-- Event: Refresh data
RegisterNetEvent('ns-market:requestRefresh', function()
    local source = source
    local citizenid = GetPlayerCitizenid(source)
    
    -- Refresh cache before sending
    LoadListings(function(listings)
        LoadBuyOrders(function(buyOrders)
            LoadPickups(function(allPickups)
                -- Add seller server ID to listings for UI comparison
                for _, listing in ipairs(listings) do
                    listing.seller = GetPlayerSourceFromCitizenid(listing.sellerCitizenid)
                end
                
                -- Add buyer server ID to buy orders for UI comparison
                for _, order in ipairs(buyOrders) do
                    order.buyer = GetPlayerSourceFromCitizenid(order.buyerCitizenid)
                end
                
                -- Get player's pickups
                local playerPickups = {}
                if citizenid then
                    for _, pickup in ipairs(allPickups) do
                        if pickup.buyerCitizenid == citizenid then
                            table.insert(playerPickups, pickup)
                        end
                    end
                end
                TriggerClientEvent('ns-market:refreshData', source, listings, buyOrders, playerPickups)
            end)
        end)
    end)
end)

-- Initialize database on resource start
CreateThread(function()
    Wait(1000) -- Wait for MySQL to be ready
    LoadListings(function()
    end)
    LoadBuyOrders(function()
    end)
end)


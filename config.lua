Config = {}

-- Marketplace Locations (add more as needed)
Config.Locations = {
    {
        name = "Legion Square Market",
        coords = vector3(194.61, -934.12, 30.69),
        ped = {
            model = "s_m_y_shop_mask",
            heading = 180.0,
            coords = vector3(194.61, -934.12, 30.69)
        },
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            label = "Marketplace"
        }
    },
    {
        name = "Paleto Bay Market",
        coords = vector3(-57.67, 6523.18, 31.49),
        ped = {
            model = "s_m_y_shop_mask",
            heading = 312.06,
            coords = vector3(-57.67, 6523.18, 31.49)
        },
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            label = "Marketplace"
        }
    }
}

-- Available items (only these items can be listed on marketplace)
-- If this list is empty, all items will be available
-- Add items to this list to restrict what can be listed
Config.AvailableItems = {
"iron",
"steel",
"aluminum",
"copper",
"rubber",
"plastic",
"scrapmetal"
}

-- Marketplace Settings
Config.Settings = {
    maxListingsPerPlayer = 20,        -- Maximum active listings per player
    maxBuyOrdersPerPlayer = 10,       -- Maximum active buy orders per player
    minPrice = 1,                      -- Minimum price for items
    maxPrice = 1000000,                -- Maximum price for items
    transactionFeePercent = 2.5,      -- Transaction fee percentage (2.5%)
    refreshInterval = 5000,            -- UI refresh interval in ms (5 seconds)
    enableAnalytics = true            -- Enable analytics tracking
}

-- Interaction Settings (ox_target handles interaction automatically)
Config.Interaction = {
    -- ox_target handles interaction distance and keybinds automatically
}


# NS Marketplace - FiveM Script

A comprehensive marketplace system for FiveM servers that allows players to buy and sell items with a modern, neon-themed UI.

## Features

- **Item Listings**: Players can list items for sale with custom quantities and prices
- **Buy Orders**: Players can create buy orders for items they want to purchase
- **Search Functionality**: Search through listings and buy orders
- **Item Blacklist**: Configurable blacklist to prevent certain items from being listed
- **Multiple Locations**: Support for multiple marketplace locations with PED interactions
- **Transaction History**: Complete history of all marketplace activity with filtering
- **Analytics**: Built-in analytics capabilities for tracking marketplace activity
- **Optimized Performance**: Designed for populated servers with efficient data handling
- **Modern UI**: Neon blue theme with shield logo matching the NS brand

## Installation

1. **Install oxmysql**: Ensure you have `oxmysql` installed and configured on your server
2. **Database Setup**: Run the SQL script in `sql/marketplace.sql` to create the necessary MySQL tables
3. **Install Resource**: Place the `ns-market` folder in your server's `resources` directory
4. **Start Resource**: Add `ensure ns-market` to your `server.cfg` (make sure it loads after `oxmysql`)
5. **Configure**: Edit `config.lua` to match your server setup
6. **Inventory Integration**: Adjust inventory system integration in `server/main.lua` if needed

## Configuration

### Locations

Edit `config.lua` to add or modify marketplace locations:

```lua
Config.Locations = {
    {
        name = "Legion Square Market",
        coords = vector3(195.0, -933.0, 30.7),
        ped = {
            model = "s_m_y_shop_mask",
            heading = 180.0,
            coords = vector3(195.0, -933.0, 30.7)
        },
        blip = {
            sprite = 52,
            color = 3,
            scale = 0.8,
            label = "Marketplace"
        }
    }
}
```

### Blacklisted Items

Add items to the blacklist in `config.lua`:

```lua
Config.BlacklistedItems = {
    "weapon_pistol",
    "weapon_rifle",
    -- Add more items here
}
```

### Settings

Adjust marketplace settings in `config.lua`:

```lua
Config.Settings = {
    maxListingsPerPlayer = 20,        -- Maximum active listings per player
    maxBuyOrdersPerPlayer = 10,       -- Maximum active buy orders per player
    minPrice = 1,                      -- Minimum price for items
    maxPrice = 1000000,                -- Maximum price for items
    transactionFeePercent = 2.5,      -- Transaction fee percentage
    refreshInterval = 5000,            -- UI refresh interval in ms
    maxHistoryEntries = 1000,          -- Maximum history entries to keep
    enableAnalytics = true            -- Enable analytics tracking
}
```

## Inventory System Integration

The script supports multiple inventory systems out of the box:
- **ox_inventory**
- **qb-inventory** (QB-Core)
- **esx_inventory** (ESX)

If you're using a different inventory system, you'll need to modify the inventory functions in `server/main.lua`:

- `GetPlayerInventory(source)`
- `AddItemToPlayer(source, item, quantity, metadata)`
- `RemoveItemFromPlayer(source, item, quantity, metadata)`
- `GetPlayerMoney(source)`
- `AddMoneyToPlayer(source, amount)`
- `RemoveMoneyFromPlayer(source, amount)`

## Usage

1. **Accessing the Marketplace**: Approach any configured marketplace location and press `E` to interact with the PED
2. **Listing Items**: Go to the "Sell Item" tab, enter item name, quantity, and price, then click "List Item"
3. **Purchasing Items**: Browse listings, select quantity, and click "Buy"
4. **Creating Buy Orders**: Go to "Create Order" tab, enter details, and create a buy order
5. **Fulfilling Orders**: View buy orders and click "Fulfill" to sell items to buyers
6. **Viewing History**: Check the "History" tab to see all marketplace activity

## Database

The marketplace uses MySQL (via oxmysql) to store all data. The database includes three main tables:

- **ns_marketplace_listings**: All active item listings
- **ns_marketplace_buy_orders**: All active buy orders
- **ns_marketplace_history**: Complete transaction history

### Database Setup

1. Ensure `oxmysql` is installed and configured on your server
2. Run the SQL script located in `sql/marketplace.sql` to create the tables:
   ```sql
   -- Execute the contents of sql/marketplace.sql in your MySQL database
   ```
3. The script will automatically create the tables on first run if they don't exist

### Database Schema

The script uses the following MySQL tables:
- **ns_marketplace_listings**: Stores item listings with seller info, prices, quantities, and metadata (JSON)
- **ns_marketplace_buy_orders**: Stores buy orders with buyer info, prices, and quantities
- **ns_marketplace_history**: Stores all marketplace transactions with timestamps and details

## Performance Optimization

The script is optimized for populated servers:
- **MySQL Database**: Uses oxmysql for efficient database operations
- **In-Memory Caching**: Listings and buy orders are cached in memory for fast access
- **Async Operations**: All database operations are asynchronous to prevent server lag
- **Client-side UI Refresh**: UI refreshes at configurable intervals
- **Server-side Validation**: All transactions are validated server-side
- **Minimal Network Traffic**: Only necessary data is sent to clients
- **Optimized Queries**: Database queries use indexes for fast lookups

## Support

For issues or questions, please check:
- Configuration settings in `config.lua`
- Inventory system compatibility
- Server console for error messages

## License

This script is provided as-is for use on FiveM servers.


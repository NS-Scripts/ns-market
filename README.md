# ns-market - FiveM Script

A comprehensive marketplace system for FiveM servers that allows players to buy and sell items.

## Features

- **Item Listings**: Players can list items for sale with custom quantities and prices
- **Buy Orders**: Players can create buy orders for items they want to purchase
- **Search Functionality**: Search through listings and buy orders
- **Item Blacklist**: Configurable blacklist to prevent certain items from being listed
- **Multiple Locations**: Support for multiple marketplace locations with PED interactions
- **Transaction History**: Complete history of all marketplace activity with filtering

Dependencies:

1. qbox, (qbcore and esx not tested)
2. ox_inventory, (qb-inventory and es_inventory not tested)

Usage

1. **Accessing the Marketplace**: Approach any configured marketplace and interact with ped.
2. **Listing Items**: Go to the "Sell Item" tab, enter item name, quantity, and price, then click "List Item"
3. **Purchasing Items**: Browse listings, select quantity, and click "Buy"
4. **Creating Buy Orders**: Go to "Create Order" tab, enter details, and create a buy order
5. **Fulfilling Orders**: View buy orders and click "Fulfill" to sell items to buyers
6. **Viewing History**: Check the "History" tab to see all marketplace activity

### Installation

1. Ensure ns-market or add to folders included in server.cfg e.g. '[standalone]'
2. Run the SQL script located in `sql/marketplace.sql` to create the tables:
3. Logo can be swapped out with same name 60x70px
4. Large list of backlisted items already in configuration, but can add more.



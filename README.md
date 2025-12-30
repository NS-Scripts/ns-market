# ns-market - FiveM Script

A comprehensive marketplace system for FiveM servers that allows players to buy and sell items.

## Features

- **Item Listings**: Players can list items for sale with custom quantities and prices
- **Buy Orders**: Players can create buy orders for items they want to purchase
- **Search Functionality**: Search through listings and buy orders
- **Item Blacklist**: Configurable blacklist to prevent certain items from being listed
- **Multiple Locations**: Support for multiple marketplace locations with PED interactions
- **Transaction History**: Complete history of all marketplace activity with filtering

## Dependencies

1. qbox, (qbcore and esx not tested)
2. ox_inventory, (qb-inventory and es_inventory not tested)

## Usage

1. **Accessing the Marketplace**: Approach any configured marketplace and interact with ped.
2. **Listing Items**: Go to the "Sell Item" tab, enter item name, quantity, and price, then click "List Item"
3. **Purchasing Items**: Browse listings, select quantity, and click "Buy"
4. **Creating Buy Orders**: Go to "Create Order" tab, enter details, and create a buy order
5. **Fulfilling Orders**: View buy orders and click "Fulfill" to sell items to buyers
6. **Viewing History**: Check the "History" tab to see all marketplace activity

## Installation

1. Ensure ns-market or add to folders included in server.cfg e.g. '[standalone]'
2. Run the SQL script located in `sql/marketplace.sql` to create the tables:
3. Logo can be swapped out with same name 60x70px
4. Large list of backlisted items already in configuration, but can add more.

## Support

For support, questions, or bug reports, please join our Discord server:

[Discord Support Server](https://discord.gg/xSCBAYFwmY)


<img width="1244" height="1268" alt="listings" src="https://github.com/user-attachments/assets/187624fb-6243-4644-b9e6-3afb67b95c74" />

<img width="1245" height="1264" alt="buyorders" src="https://github.com/user-attachments/assets/2ebc5720-6dce-45f6-bb1d-cb118c55b1c1" />

<img width="1231" height="1258" alt="pickups" src="https://github.com/user-attachments/assets/33404ffe-06e0-4df5-82a9-447b5e7d4f2c" />

<img width="1226" height="1257" alt="sellitem" src="https://github.com/user-attachments/assets/7cc02785-7551-4cba-b34d-373fcbd1bcb8" />

<img width="1230" height="1261" alt="createorder" src="https://github.com/user-attachments/assets/22b15abb-8fd7-440a-ab44-c5d84a34208b" />

<img width="1234" height="1265" alt="history" src="https://github.com/user-attachments/assets/845d3a94-85f1-4d4d-8058-3f44c138025f" />




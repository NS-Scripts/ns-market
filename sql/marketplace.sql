-- NS Marketplace MySQL Schema
-- Run this SQL script to create the necessary tables

CREATE TABLE IF NOT EXISTS `ns_marketplace_listings` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `seller_citizenid` VARCHAR(50) NOT NULL,
    `seller_firstname` VARCHAR(100) NOT NULL,
    `seller_lastname` VARCHAR(100) NOT NULL,
    `item` VARCHAR(100) NOT NULL,
    `quantity` INT(11) NOT NULL,
    `price` INT(11) NOT NULL,
    `total_price` INT(11) NOT NULL,
    `metadata` JSON DEFAULT NULL,
    `created` INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `seller_citizenid` (`seller_citizenid`),
    KEY `item` (`item`),
    KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ns_marketplace_buy_orders` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `buyer_citizenid` VARCHAR(50) NOT NULL,
    `buyer_firstname` VARCHAR(100) NOT NULL,
    `buyer_lastname` VARCHAR(100) NOT NULL,
    `item` VARCHAR(100) NOT NULL,
    `quantity` INT(11) NOT NULL,
    `price` INT(11) NOT NULL,
    `total_price` INT(11) NOT NULL,
    `created` INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `buyer_citizenid` (`buyer_citizenid`),
    KEY `item` (`item`),
    KEY `created` (`created`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ns_marketplace_history` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `type` VARCHAR(50) NOT NULL,
    `listing_id` INT(11) DEFAULT NULL,
    `order_id` INT(11) DEFAULT NULL,
    `seller_citizenid` VARCHAR(50) DEFAULT NULL,
    `seller_firstname` VARCHAR(100) DEFAULT NULL,
    `seller_lastname` VARCHAR(100) DEFAULT NULL,
    `buyer_citizenid` VARCHAR(50) DEFAULT NULL,
    `buyer_firstname` VARCHAR(100) DEFAULT NULL,
    `buyer_lastname` VARCHAR(100) DEFAULT NULL,
    `item` VARCHAR(100) NOT NULL,
    `quantity` INT(11) NOT NULL,
    `price` INT(11) NOT NULL,
    `total_price` INT(11) DEFAULT NULL,
    `fee` INT(11) DEFAULT NULL,
    `timestamp` INT(11) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `type` (`type`),
    KEY `item` (`item`),
    KEY `seller_citizenid` (`seller_citizenid`),
    KEY `buyer_citizenid` (`buyer_citizenid`),
    KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `ns_marketplace_pickups` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `order_id` INT(11) NOT NULL,
    `buyer_citizenid` VARCHAR(50) NOT NULL,
    `buyer_firstname` VARCHAR(100) NOT NULL,
    `buyer_lastname` VARCHAR(100) NOT NULL,
    `seller_citizenid` VARCHAR(50) NOT NULL,
    `seller_firstname` VARCHAR(100) NOT NULL,
    `seller_lastname` VARCHAR(100) NOT NULL,
    `item` VARCHAR(100) NOT NULL,
    `quantity` INT(11) NOT NULL,
    `price` INT(11) NOT NULL,
    `total_price` INT(11) NOT NULL,
    `metadata` JSON DEFAULT NULL,
    `fulfilled_timestamp` INT(11) NOT NULL,
    `picked_up` TINYINT(1) DEFAULT 0,
    PRIMARY KEY (`id`),
    KEY `buyer_citizenid` (`buyer_citizenid`),
    KEY `picked_up` (`picked_up`),
    KEY `order_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


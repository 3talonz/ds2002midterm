CREATE DATABASE IF NOT EXISTS `sakila_dw`;

CREATE TABLE IF NOT EXISTS `dim_date` (
	`date_key` int NOT NULL PRIMARY KEY,
    `full_date` date UNIQUE NOT NULL,
    `day` int NOT NULL,
    `month` int NOT NULL,
    `month_name` varchar(10) NOT NULL,
    `quarter` int NOT NULL,
    `year` int NOT NULL,
    `day_of_week` int NOT NULL,
    `is_weekend` int NOT NULL,
    `week_of_year` int NOT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `dim_customer` (
  `customer_key` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `customer_id` int NOT NULL UNIQUE,
  `store_id` int NOT NULL,
  `first_name` varchar(50) DEFAULT NULL,
  `last_name` varchar(50) DEFAULT NULL,
  `email` varchar(50) DEFAULT NULL,
  `address` varchar(50) NOT NULL,
  `district` varchar(50) NOT NULL,
  `city` varchar(50) NOT NULL,
  `country` varchar(50) NOT NULL,
  `postal_code` varchar(50) NOT NULL,
  `create_date` datetime DEFAULT NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_staff (
  `staff_key` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `staff_id` int NOT NULL UNIQUE,
  `first_name` varchar(50),
  `last_name` varchar(50),
  `email` varchar(50),
  `store_id` int,
  `username` varchar(50)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_store (
  `store_key` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `store_id` int NOT NULL UNIQUE,
  `address` varchar(50) NOT NULL,
  `district` varchar(50) NOT NULL,
  `city` varchar(50) NOT NULL,
  `country` varchar(50) NOT NULL,
  `manager_staff_id` int
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS dim_film (
  `film_key` int NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `film_id` int NOT NULL UNIQUE,
  `title` varchar(255),
  `release_year` year,
  `rating`  varchar(10),
  `length_min` int,
  `rental_duration` int,
  `rental_rate`  decimal(4,2),
  `replacement_cost` decimal(5,2),
  `categories` varchar(255)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `fact_payments` (
  `payment_id` int NOT NULL PRIMARY KEY,
  `customer_key` int NOT NULL,
  `staff_key` int NOT NULL,
  `store_key` int NOT NULL,
  `film_key` int DEFAULT NULL, 
  `payment_date_key` int NOT NULL,
  `amount` decimal(5,2) NOT NULL,
  `rental_id` int DEFAULT NULL,
  KEY `fact_payments_date` (`payment_date_key`),
  KEY `fact_payments_dims` (`customer_key`, `staff_key`, `store_key`, `film_key`),

  CONSTRAINT `fk_fact_customer` FOREIGN KEY (`customer_key`) REFERENCES `dim_customer`(`customer_key`),
  CONSTRAINT `fk_fact_staff` FOREIGN KEY (`staff_key`) REFERENCES `dim_staff`(`staff_key`),
  CONSTRAINT `fk_fact_store` FOREIGN KEY (`store_key`) REFERENCES `dim_store`(`store_key`),
  CONSTRAINT `fk_fact_film` FOREIGN KEY (`film_key`) REFERENCES `dim_film`(`film_key`),
  CONSTRAINT `fk_fact_paydate` FOREIGN KEY (`payment_date_key`) REFERENCES `dim_date`(`date_key`)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
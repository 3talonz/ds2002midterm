USE sakila_dw;

# date dimension (I got this from chat because I genuinely could not make the other one work)
SET @min_date := (SELECT DATE(MIN(payment_date)) FROM sakila.payment);
SET @max_date := (SELECT DATE(MAX(payment_date)) FROM sakila.payment);
SET @min_date := IFNULL(@min_date, DATE('2005-01-01'));
SET @max_date := IFNULL(@max_date, DATE('2006-12-31'));

SET @span := DATEDIFF(@max_date, @min_date);

INSERT IGNORE INTO `dim_date`
(`date_key`,`full_date`,`day`,`month`,`month_name`,`quarter`,`year`,`day_of_week`,`is_weekend`,`week_of_year`)
SELECT
  DATE_FORMAT(DATE_ADD(@min_date, INTERVAL n DAY), '%Y%m%d') + 0 AS date_key,
  DATE_ADD(@min_date, INTERVAL n DAY) AS full_date,
  DAY(DATE_ADD(@min_date, INTERVAL n DAY)) AS `day`,
  MONTH(DATE_ADD(@min_date, INTERVAL n DAY)) AS `month`,
  DATE_FORMAT(DATE_ADD(@min_date, INTERVAL n DAY), '%M') AS month_name,
  QUARTER(DATE_ADD(@min_date, INTERVAL n DAY)) AS `quarter`,
  YEAR(DATE_ADD(@min_date, INTERVAL n DAY)) AS `year`,
  WEEKDAY(DATE_ADD(@min_date, INTERVAL n DAY)) + 1 AS day_of_week,  -- 1=Mon..7=Sun
  (WEEKDAY(DATE_ADD(@min_date, INTERVAL n DAY)) >= 5) AS is_weekend, 
  WEEKOFYEAR(DATE_ADD(@min_date, INTERVAL n DAY)) AS week_of_year
FROM (
  SELECT a.i + b.i*10 + c.i*100 + d.i*1000 AS n
  FROM (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
 CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
 CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c
 CROSS JOIN (SELECT 0 i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
        UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d
) t
WHERE n <= @span;

INSERT INTO `dim_customer`
(`customer_id`,`store_id`,`first_name`,`last_name`,`email`,
 `address`,`district`,`city`,`country`,`postal_code`,`create_date`)
SELECT
  c.customer_id,
  c.store_id,
  c.first_name,
  c.last_name,
  c.email,
  a.address,
  a.district,
  ci.city,
  co.country,
  a.postal_code,
  c.create_date
FROM sakila.customer c
JOIN sakila.address a ON c.address_id = a.address_id
JOIN sakila.city    ci ON a.city_id   = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id;
  
INSERT INTO `dim_staff`
(`staff_id`,`first_name`,`last_name`,`email`,`store_id`,`username`)
SELECT
  s.staff_id,
  s.first_name,
  s.last_name,
  s.email,
  s.store_id,
  s.username
FROM sakila.staff s;

INSERT INTO `dim_store`
(`store_id`,`address`,`district`,`city`,`country`,`manager_staff_id`)
SELECT
  st.store_id,
  a.address,
  a.district,
  ci.city,
  co.country,
  st.manager_staff_id
FROM sakila.store st
JOIN sakila.address a ON st.address_id = a.address_id
JOIN sakila.city    ci ON a.city_id    = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id;
  
INSERT INTO `dim_film`
(`film_id`,`title`,`release_year`,`rating`,`length_min`,
 `rental_duration`,`rental_rate`,`replacement_cost`,`categories`)
SELECT
  f.film_id,
  f.title,
  f.release_year,
  f.rating,
  f.length,
  f.rental_duration,
  f.rental_rate,
  f.replacement_cost,
  GROUP_CONCAT(c.name ORDER BY c.name SEPARATOR ', ') AS categories
FROM sakila.film f
LEFT JOIN sakila.film_category fc ON f.film_id = fc.film_id
LEFT JOIN sakila.category c       ON fc.category_id = c.category_id
GROUP BY
  f.film_id, f.title, f.release_year, f.rating, f.length,
  f.rental_duration, f.rental_rate, f.replacement_cost;
  
INSERT INTO `fact_payments`
  (`payment_id`,`customer_key`,`staff_key`,`store_key`,`film_key`,
   `payment_date_key`,`amount`,`rental_id`)
SELECT
  p.payment_id,
  dc.customer_key,
  ds.staff_key,
  dstore.store_key,
  df.film_key,
  DATE_FORMAT(p.payment_date, '%Y%m%d') + 0 AS payment_date_key,
  p.amount,
  p.rental_id
FROM sakila.payment p
JOIN `dim_customer` dc
  ON dc.`customer_id` = p.`customer_id`
JOIN `dim_staff` ds
  ON ds.`staff_id` = p.`staff_id`
JOIN `dim_store` dstore
  ON dstore.`store_id` = ds.`store_id`
JOIN `dim_date` d
  ON d.`date_key` = DATE_FORMAT(p.payment_date, '%Y%m%d') + 0
LEFT JOIN sakila.rental r
  ON p.`rental_id` = r.`rental_id`
LEFT JOIN sakila.inventory i
  ON r.`inventory_id` = i.`inventory_id`
LEFT JOIN `dim_film` df
  ON df.`film_id` = i.`film_id`;
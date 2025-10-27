# ds2002midterm
## To run
* Build source database by running files in Sakila Database subdirectory (should already come installed on MySQLWorkbench though)
* Run 1CreateWarehouse.sql to build warehouse database on MySQL Workbench
* Run 2PopulateWarehouse.sql to populate warehouse with actual data from sakila
* Run 3LoadCSV.py to pull data from "CountriesContinents.csv", add staging table to MySQL server, and enrich "dim_customer" table through "continent" column (dataset taken from https://www.kaggle.com/datasets/hserdaraltan/countries-by-continent)
* Run 4MongoDB.ipynb to pull data from MongoDB NoSQL database, add staging table to MySQL server, and enrich "dim_customer" table through "loyalty_tier" and "loyalty_score" columns (json version of MongoDB data attached in this repo as "mongodb_data.json", database named "sakila_nosql", collection named "customer_profiles")
* Run 5TestQueries.sql to see queries which test/demonstrate functionality
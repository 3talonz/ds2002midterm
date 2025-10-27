import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.types import String

#original database before modifications from: https://www.kaggle.com/datasets/hserdaraltan/countries-by-continent

mysql_args = {
    "uid" : "root",
    "pwd" : "SoupbruhSm3lls!",
    "hostname" : "localhost",
    "dbname" : "sakila_dw"
}

def get_sql_dataframe(sql_query, **args):
    '''Create a connection to the MySQL database'''
    conn_str = f"mysql+pymysql://{args['uid']}:{args['pwd']}@{args['hostname']}/{args['dbname']}"
    sqlEngine = create_engine(conn_str, pool_recycle=3600)
    connection = sqlEngine.connect()
    
    '''Invoke the pd.read_sql() function to query the database, and fill a Pandas DataFrame.'''
    dframe = pd.read_sql(text(sql_query), connection)
    connection.close()
    
    return dframe
    

def set_dataframe(df, table_name, pk_column, db_operation, **args):
    conn_str = f"mysql+pymysql://{args['uid']}:{args['pwd']}@{args['hostname']}/{args['dbname']}"
    sqlEngine = create_engine(conn_str, pool_recycle=3600)

    # normalize column names and values
    df = df.copy()
    df.columns = [c.strip().lower() for c in df.columns]
    if "country" in df.columns:
        df["country"] = df["country"].str.strip()
    if "continent" in df.columns:
        df["continent"] = df["continent"].str.strip()
    if "country" in df.columns:
        df = df.drop_duplicates(subset=["country"])

    with sqlEngine.begin() as connection:
        if db_operation == "insert":
            df.to_sql(
                table_name,
                con=connection,
                index=False,
                if_exists='replace',
                dtype={
                    "country": String(128),
                    "continent": String(64),
                },
            )
            connection.execute(text(f"ALTER TABLE {table_name} ADD PRIMARY KEY ({pk_column});"))

        elif db_operation == "update":
            df.to_sql(table_name, con=connection, index=False, if_exists='append')

df = pd.read_csv("CountriesContinents.csv", dtype=str)[["Continent","Country"]].dropna()
df.columns = ["continent", "country"]  # normalize beforehand

# build staging table for country and continent
set_dataframe(df, table_name="stg_country_continent", pk_column="country", db_operation="insert", **mysql_args)

# add continent column to dim_customer and populate it 
conn_str = f"mysql+pymysql://{mysql_args['uid']}:{mysql_args['pwd']}@{mysql_args['hostname']}/{mysql_args['dbname']}"
sqlEngine = create_engine(conn_str, pool_recycle=3600)
with sqlEngine.begin() as conn:
    # check if continent exists
    exists = conn.execute(text("""
        SELECT 1
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = :schema
          AND TABLE_NAME   = 'dim_customer'
          AND COLUMN_NAME  = 'continent'
        LIMIT 1
    """), {"schema": mysql_args["dbname"]}).scalar()

    if not exists:
        conn.execute(text("ALTER TABLE dim_customer ADD COLUMN continent VARCHAR(64)"))

    # update continent
    conn.execute(text("""
        UPDATE dim_customer d
        JOIN stg_country_continent s
          ON TRIM(s.country) = TRIM(d.country)
        SET d.continent = s.continent
    """))

# reported unmatched countries
unmatched = get_sql_dataframe("""
    SELECT DISTINCT d.country
    FROM dim_customer d
    LEFT JOIN stg_country_continent s ON TRIM(s.country) = TRIM(d.country)
    WHERE s.country IS NULL
    ORDER BY d.country
""", **mysql_args)

print(f"Assigned continents to customers. Unmatched countries: {len(unmatched)}")
if not unmatched.empty:
    print(unmatched.to_string(index=False))
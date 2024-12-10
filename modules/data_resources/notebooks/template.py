# Import required PySpark libraries
from pyspark.sql import SparkSession
from pyspark.sql.functions import *

# Configuration for storage paths, catalog, and schemas
CONFIG = {
    'catalog_name': 'client_dev_catalog',
    'bronze_schema': 'bronze_container_schema',
    'gold_schema': 'gold_container_schema',
    'storage_account': 'datalake account name',
    'bronze_path': 'abfss://bronze@{storage_account}.dfs.core.windows.net/vitalsigns/date=*/hour=*/*.gz',
    'gold_path': 'abfss://gold@{storage_account}.dfs.core.windows.net/output'
}

# Format storage paths using the storage account name
CONFIG['bronze_path'] = CONFIG['bronze_path'].format(storage_account=CONFIG['storage_account'])
CONFIG['gold_path'] = CONFIG['gold_path'].format(storage_account=CONFIG['storage_account'])

# Create a Spark session with Unity Catalog enabled
spark = SparkSession.builder \
    .appName("Azure Data Lake Access") \
    .getOrCreate()

try:
    # Set the catalog 
    print("Setting up Unity Catalog context...")
    spark.sql(f"USE CATALOG {CONFIG['catalog_name']}")
    
    # Use bronze schema
    print("\nUsing bronze schema for reading...")
    spark.sql(f"USE SCHEMA {CONFIG['bronze_schema']}")
    
    # Read using bronze schema
    bronze_data_sample = spark.read.format("json") \
        .load(CONFIG['bronze_path']) \
        .limit(2)

    print("Sample data:")
    bronze_data_sample.show()

    # Use gold schema
    print("\nUsing gold schema for writing...")
    spark.sql(f"USE SCHEMA {CONFIG['gold_schema']}")

    # Write using gold schema
    bronze_data_sample.write \
        .format("parquet") \
        .mode("overwrite") \
        .save(CONFIG['gold_path'])
   
    print("Write operation completed successfully")
       
except Exception as e:
    print(f"Error: {str(e)}")
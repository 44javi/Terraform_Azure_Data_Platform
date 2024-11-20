from pyspark.sql import SparkSession

# Initialize Spark Session with managed identity configuration
spark = SparkSession.builder \
    .appName("GZIP_Parquet_Test") \
    .config("fs.azure.account.auth.type", "CustomAccessToken") \
    .config("fs.azure.account.custom.token.provider.class", spark.conf.get("spark.databricks.passthrough.adls.gen2.tokenProviderClassName")) \
    .getOrCreate()

# Get parameters from Databricks widgets
dbutils.widgets.text("storage_account_name", "", "Storage Account Name")
dbutils.widgets.text("container_bronze", "", "Bronze Container Name")
dbutils.widgets.text("container_gold", "", "Gold Container Name")

# Storage account details
storage_account_name = dbutils.widgets.get("storage_account_name")
container_bronze = dbutils.widgets.get("container_bronze")
container_gold = dbutils.widgets.get("container_gold")

# Test connectivity function
def test_storage_connectivity():
    try:
        # Test reading (list files in bronze container)
        bronze_path = f"abfss://{container_bronze}@{storage_account_name}.dfs.core.windows.net/"
        bronze_files = dbutils.fs.ls(bronze_path)
        print("Successfully listed files in bronze container:")
        for file in bronze_files:
            print(f"Found: {file.path}")
            
        # Test writing (create a small test file in gold container)
        test_data = [(1, "test"), (2, "test2")]
        test_df = spark.createDataFrame(test_data, ["id", "value"])
        
        gold_output_path = f"abfss://{container_gold}@{storage_account_name}.dfs.core.windows.net/test_output"
        test_df.write.mode("overwrite").parquet(gold_output_path)
        print("\nSuccessfully wrote test file to gold container")
        
        # Verify the written file
        gold_files = dbutils.fs.ls(gold_output_path)
        print("\nVerified written files:")
        for file in gold_files:
            print(f"Written: {file.path}")
            
        return True
        
    except Exception as e:
        print(f"Error testing storage connectivity: {str(e)}")
        return False

# Main execution
print("Starting storage connectivity test...")
success = test_storage_connectivity()
if success:
    print("\nStorage connectivity test passed successfully!")
else:
    print("\nStorage connectivity test failed!")
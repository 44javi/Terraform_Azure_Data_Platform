resource "databricks_job" "gzip_to_parquet_job" {
  name     = "${var.client}_gzip_to_parquet_job_${var.suffix}"
  job_cluster {
    job_cluster_key = "gzip_parquet_cluster"
    new_cluster {
      spark_version = "14.3.x-photon-scala2.12"
      node_type_id  = "Standard_D3_v2"
     
      # Single-node configuration
      spark_conf = {
        "spark.databricks.cluster.profile" : "singleNode"
        "spark.master" : "local[*]"
       
        # Azure Data Lake Storage access configuration
        "spark.databricks.passthrough.enabled": "true"
        "spark.databricks.azure.adls.gen2.implementation.enabled": "true"
       
        # Performance optimizations
        "spark.databricks.photon.enabled" : "true"
        "spark.databricks.io.cache.enabled" : "true"
      }

      custom_tags = {
        "ResourceClass" = "SingleNode"
        "Environment"   = "Development"
        "Version"      = "LTS-14.3"
        "DatabricksIdentityId" = var.databricks_identity_id
      }

      azure_attributes {
        first_on_demand = 1
        availability    = "ON_DEMAND_AZURE"
        spot_bid_max_price = -1
      }
    }
  }

  task {
    task_key = "gzip_to_parquet_task"
   
    notebook_task {
      notebook_path = var.notebook_path
      base_parameters = {
        storage_account_name = var.storage_account_name
        container_bronze    = var.bronze_container
        container_gold     = var.gold_container
      }
    }

    job_cluster_key = "gzip_parquet_cluster"
  }

  /*
  # Set a schedule
  schedule {
    quartz_cron_expression = "0 0 * ** ?" # Run every hour
    timezone_id = "UTC"
  }
  */
}
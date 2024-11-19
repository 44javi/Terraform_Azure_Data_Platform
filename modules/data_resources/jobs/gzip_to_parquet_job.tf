# Databricks Job using a Job Cluster
resource "databricks_job" "gzip_to_parquet_job" {
  name     = "${var.client}_gzip_to_parquet_job_${var.suffix}"

  job_cluster {
    job_cluster_key = "gzip_parquet_cluster"
    new_cluster {
      spark_version = "14.3.x-photon-scala2.12"  # Latest LTS version with Photon
      node_type_id  = "Standard_D3_v2"
      
      # Single-node configuration
      spark_conf = {
        # Cluster configuration
        "spark.databricks.cluster.profile" : "singleNode"
        "spark.master" : "local[*]"
        
        # OAuth configuration for ADLS access
        "fs.azure.account.auth.type" : "OAuth"
        "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
        "fs.azure.account.oauth2.client.id" : var.managed_identity_client_id
        "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${var.tenant_id}/oauth2/token"
        
        # Performance optimizations
        "spark.databricks.photon.enabled" : "true"
        "spark.databricks.io.cache.enabled" : "true"
      }

      custom_tags = {
        "ResourceClass" = "SingleNode"
        "Environment"   = "Development"
        "Version"      = "LTS-14.3"
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
    quartz_cron_expression = "0 0 * * * ?" # Run every hour
    timezone_id = "UTC"
  }
*/

}
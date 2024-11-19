output "job_url" {
  description = "URL to the created job in Databricks workspace"
  value       = databricks_job.gzip_to_parquet_job.url
}

output "job_id" {
  description = "ID of the created Databricks job"
  value       = databricks_job.gzip_to_parquet_job.id
}
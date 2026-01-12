output "database_name" {
  description = "Glue Data Catalog database name"
  value       = aws_glue_catalog_database.this.name
}

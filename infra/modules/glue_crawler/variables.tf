variable "crawler_name" {
  type        = string
  description = "Name of the Glue crawler"
}

variable "iam_role_arn" {
  type        = string
  description = "IAM role ARN assumed by the crawler"
}

variable "database_name" {
  type        = string
  description = "Glue Data Catalog database name"
}

variable "s3_path" {
  type        = string
  description = "S3 path the crawler scans"
}

variable "table_prefix" {
  type        = string
  description = "Prefix for tables created by the crawler"
}

variable "description" {
  type        = string
  description = "Crawler description"
}

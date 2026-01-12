variable "principal_arn" {
  type        = string
  description = "IAM role ARN to grant Lake Formation permissions to"
}

variable "database_name" {
  type        = string
  description = "Glue Data Catalog database name"
}

variable "permissions" {
  type        = list(string)
  description = "Lake Formation permissions to grant"
}

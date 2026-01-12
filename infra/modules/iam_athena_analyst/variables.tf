variable "role_name" {
  type        = string
  description = "Name of the Athena analyst IAM role"
}

variable "trusted_principal_arn" {
  type        = string
  description = "ARN of IAM user or role allowed to assume this role"
}

variable "athena_results_s3_arns" {
  type        = list(string)
  description = "S3 ARNs for Athena query results bucket"
}

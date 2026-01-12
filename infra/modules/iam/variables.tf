variable "role_name" {
  type        = string
  description = "Name of the Glue IAM role"
}

variable "s3_arns" {
  type        = list(string)
  description = "List of S3 bucket and object ARNs Glue can access"
}

variable "kms_key_arns" {
  type        = list(string)
  description = "List of KMS key ARNs Glue can use"
}

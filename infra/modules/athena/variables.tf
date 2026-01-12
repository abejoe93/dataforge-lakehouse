variable "workgroup_name" {
  type        = string
  description = "Athena workgroup name"
}

variable "description" {
  type        = string
  description = "Description of the Athena workgroup"
}

variable "output_location" {
  type        = string
  description = "S3 location for Athena query results"
}

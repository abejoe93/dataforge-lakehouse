variable "job_name" {
  type = string
}

variable "iam_role_arn" {
  type = string
}

variable "script_location" {
  type = string
}

variable "number_of_workers" {
  type    = number
  default = 2
}

variable "raw_database" {
  type = string
}

variable "raw_table" {
  type = string
}

variable "curated_bucket" {
  type = string
}

variable "curated_prefix" {
  type = string
}

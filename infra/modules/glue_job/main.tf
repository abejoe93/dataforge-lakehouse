resource "aws_glue_job" "this" {
  name     = var.job_name
  role_arn = var.iam_role_arn

  command {
    name            = "glueetl"
    script_location = var.script_location
    python_version  = "3"
  }

  glue_version = "4.0"
  worker_type  = "G.1X"
  number_of_workers = var.number_of_workers

  default_arguments = {
    "--job-language"        = "python"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-metrics"     = "true"

    "--RAW_DATABASE"       = var.raw_database
    "--RAW_TABLE"          = var.raw_table
    "--CURATED_BUCKET"     = var.curated_bucket
    "--CURATED_PREFIX"     = var.curated_prefix
  }
}

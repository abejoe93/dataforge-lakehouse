module "kms_raw" {
  source      = "../../modules/kms"
  description = "Raw zone encryption key"
  alias       = "lakehouse-raw-prod"
}

module "kms_curated" {
  source      = "../../modules/kms"
  description = "Curated zone encryption key"
  alias       = "lakehouse-curated-prod"
}

module "raw_bucket" {
  source      = "../../modules/s3_bucket"
  bucket_name = "lakehouse-raw-prod-dataforge"
  kms_key_arn = module.kms_raw.key_arn
}

module "curated_bucket" {
  source      = "../../modules/s3_bucket"
  bucket_name = "lakehouse-curated-prod-dataforge"
  kms_key_arn = module.kms_curated.key_arn
}

module "glue_iam" {
  source        = "../../modules/iam"
  role_name     = "glue-lakehouse-prod"
  s3_arns       = [
    "arn:aws:s3:::lakehouse-raw-prod-*",
    "arn:aws:s3:::lakehouse-raw-prod-*/*",
    "arn:aws:s3:::lakehouse-curated-prod-*",
    "arn:aws:s3:::lakehouse-curated-prod-*/*"
  ]
  kms_key_arns  = [
    module.kms_raw.key_arn,
    module.kms_curated.key_arn
  ]
}

module "glue_raw_db" {
  source        = "../../modules/glue"
  database_name = "raw_prod"
  description   = "Raw zone Glue catalog database (prod)"
}

module "glue_curated_db" {
  source        = "../../modules/glue"
  database_name = "curated_prod"
  description   = "Curated zone Glue catalog database (prod)"
}

module "lf_raw_db_permissions" {
  source        = "../../modules/lakeformation"
  principal_arn = module.glue_iam.role_arn
  database_name = module.glue_raw_db.database_name
  permissions   = ["ALL"]
}

module "lf_curated_db_permissions" {
  source        = "../../modules/lakeformation"
  principal_arn = module.glue_iam.role_arn
  database_name = module.glue_curated_db.database_name
  permissions   = ["ALL"]
}

module "raw_crawler" {
  source        = "../../modules/glue_crawler"
  crawler_name  = "raw-zone-crawler-prod"
  iam_role_arn = module.glue_iam.role_arn
  database_name = module.glue_raw_db.database_name
  s3_path       = "s3://${module.raw_bucket.bucket_name}/events/"
  table_prefix  = "raw_"
  description   = "Crawler for raw zone data (prod)"
}

module "curated_crawler" {
  source        = "../../modules/glue_crawler"
  crawler_name  = "curated-zone-crawler-prod"
  iam_role_arn = module.glue_iam.role_arn
  database_name = module.glue_curated_db.database_name
  s3_path       = "s3://${module.curated_bucket.bucket_name}/events/"
  table_prefix  = "curated_"
  description   = "Crawler for curated zone data (prod)"
}

module "raw_to_curated_job" {
  source            = "../../modules/glue_job"
  job_name          = "raw-to-curated-prod"
  iam_role_arn      = module.glue_iam.role_arn
  script_location   = "s3://${module.raw_bucket.bucket_name}/scripts/raw_to_curated.py"
  raw_database      = module.glue_raw_db.database_name
  raw_table         = "raw_events"
  curated_bucket    = module.curated_bucket.bucket_name
  curated_prefix    = "events"
  number_of_workers = 2
}

module "athena_results_bucket" {
  source        = "../../modules/s3_bucket"
  bucket_name   = "athena-results-prod-dataforge"
  kms_key_arn   = module.kms_curated.key_arn
}

module "athena_workgroup" {
  source          = "../../modules/athena"
  workgroup_name  = "analytics-prod"
  description     = "Athena workgroup for analytics queries (prod)"
  output_location = "s3://${module.athena_results_bucket.bucket_name}/results/"
}

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
  crawler_name  = "raw-zone-crawler-dev"
  iam_role_arn = module.glue_iam.role_arn
  database_name = module.glue_raw_db.database_name
  s3_path       = "s3://${module.raw_bucket.bucket_name}/"
  table_prefix  = "raw_"
  description   = "Crawler for raw zone data (dev)"
}

module "curated_crawler" {
  source        = "../../modules/glue_crawler"
  crawler_name  = "curated-zone-crawler-dev"
  iam_role_arn = module.glue_iam.role_arn
  database_name = module.glue_curated_db.database_name
  s3_path       = "s3://${module.curated_bucket.bucket_name}/"
  table_prefix  = "curated_"
  description   = "Crawler for curated zone data (dev)"
}

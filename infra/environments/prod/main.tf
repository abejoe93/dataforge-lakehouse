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

module "athena_analyst_role" {
  source                = "../../modules/iam_athena_analyst"
  role_name             = "athena-analyst-prod"
  trusted_principal_arn = "arn:aws:iam::195343369122:root"

  athena_results_s3_arns = [
    "arn:aws:s3:::${module.athena_results_bucket.bucket_name}",
    "arn:aws:s3:::${module.athena_results_bucket.bucket_name}/*"
  ]
}

resource "aws_lakeformation_permissions" "analyst_curated_events_read" {
  principal   = module.athena_analyst_role.role_arn

  permissions = ["DESCRIBE", "SELECT"]

  table {
    database_name = module.glue_curated_db.database_name
    name          = "curated_events"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_lakeformation_data_lake_settings" "this" {
  admins = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-platform-admin",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lakeformation-admin"
  ]
}


data "aws_iam_role" "lf_data_access" {
  name = "AWSServiceRoleForLakeFormationDataAccess"
}

resource "aws_lakeformation_resource" "curated_location" {
  # Use the bucket ARN (not s3://)
  arn = "arn:aws:s3:::${module.curated_bucket.bucket_name}"

  # LF mode (NOT hybrid)
  hybrid_access_enabled = false

  # Use the LF service-linked role for data access orchestration
  use_service_linked_role = true

  # Optional but recommended: ensure LF settings applied first
  depends_on = [aws_lakeformation_data_lake_settings.this]
}

resource "aws_lakeformation_permissions" "analyst_curated_location_access" {
  principal   = module.athena_analyst_role.role_arn
  permissions = ["DATA_LOCATION_ACCESS"]

  data_location {
    arn = aws_lakeformation_resource.curated_location.arn
  }
}

resource "aws_lakeformation_permissions" "tf_admin_curated_db" {
  principal   = "arn:aws:iam::195343369122:role/terraform-platform-admin"
  permissions = ["DESCRIBE"]

  database {
    name = "curated_prod"
  }
}

resource "aws_lakeformation_permissions" "tf_admin_raw_db" {
  principal   = "arn:aws:iam::195343369122:role/terraform-platform-admin"
  permissions = ["DESCRIBE"]

  database {
    name = "raw_prod"
  }
}


############################################
# Lake Formation: Table-level permissions
############################################

resource "aws_lakeformation_permissions" "analyst_curated_events_table" {
  principal = module.athena_analyst_role.role_arn

  permissions = [
    "DESCRIBE",
    "SELECT"
  ]

  table {
    database_name = "curated_prod"
    name          = "curated_events"
  }
}

############################################
# Lake Formation: Column-level permissions
############################################

resource "aws_lakeformation_permissions" "analyst_curated_events_columns" {
  principal = module.athena_analyst_role.role_arn

  permissions = ["SELECT"]

  table_with_columns {
    database_name = "curated_prod"
    name          = "curated_events"
    column_names = [
      "event_time",
      "event_type",
      "event_date"
    ]
  }

  depends_on = [
    aws_lakeformation_permissions.analyst_curated_events_table
  ]
}


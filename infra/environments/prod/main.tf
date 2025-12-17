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

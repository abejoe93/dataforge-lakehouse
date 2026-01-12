resource "aws_glue_crawler" "this" {
  name          = var.crawler_name
  role          = var.iam_role_arn
  database_name = var.database_name
  description   = var.description

  s3_target {
    path = var.s3_path
  }

  table_prefix = var.table_prefix

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })
}

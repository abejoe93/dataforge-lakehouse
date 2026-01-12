resource "aws_lakeformation_permissions" "database_permissions" {
  principal   = var.principal_arn

  permissions = var.permissions

  database {
    name = var.database_name
  }
}

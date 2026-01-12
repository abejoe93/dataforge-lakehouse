resource "aws_athena_workgroup" "this" {
  name        = var.workgroup_name
  description = var.description
  state       = "ENABLED"

  configuration {
    enforce_workgroup_configuration = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = var.output_location

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}

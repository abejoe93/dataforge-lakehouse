output "role_arn" {
  description = "ARN of the Glue execution role"
  value       = aws_iam_role.glue_role.arn
}

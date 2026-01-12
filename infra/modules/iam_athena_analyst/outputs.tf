output "role_arn" {
  description = "ARN of the Athena analyst role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the Athena analyst role"
  value       = aws_iam_role.this.name
}

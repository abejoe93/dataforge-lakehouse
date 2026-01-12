resource "aws_kms_key" "this" {
  description             = var.description
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy = data.aws_iam_policy_document.kms_key_policy.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_iam_role" "lakeformation_data_access" {
  name = "AWSServiceRoleForLakeFormationDataAccess"
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid    = "EnableIAMUserPermissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowLakeFormationDataAccessRole"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_role.lakeformation_data_access.arn]
    }

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}

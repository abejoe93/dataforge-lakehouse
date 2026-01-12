data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = var.s3_arns
  }
}

resource "aws_iam_policy" "glue_s3_policy" {
  name   = "${var.role_name}-s3"
  policy = data.aws_iam_policy_document.glue_s3_access.json
}

resource "aws_iam_role_policy_attachment" "glue_s3_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_policy.arn
}

data "aws_iam_policy_document" "glue_kms_access" {
  statement {
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]

    resources = var.kms_key_arns
  }
}

resource "aws_iam_policy" "glue_kms_policy" {
  name   = "${var.role_name}-kms"
  policy = data.aws_iam_policy_document.glue_kms_access.json
}

resource "aws_iam_role_policy_attachment" "glue_kms_attach" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_kms_policy.arn
}

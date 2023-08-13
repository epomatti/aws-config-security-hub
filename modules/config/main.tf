resource "aws_config_configuration_recorder_status" "foo" {
  name       = aws_config_configuration_recorder.foo.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.foo]
}

resource "aws_iam_role_policy_attachment" "a" {
  role       = aws_iam_role.r.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "random_string" "s3_affix" {
  length  = 10
  special = false
  upper   = false
}

resource "aws_s3_bucket" "b" {
  bucket        = "awsconfig-${random_string.s3_affix.result}"
  force_destroy = true
}

resource "aws_sns_topic" "config" {
  name = "user-updates-topic"
}

resource "aws_config_delivery_channel" "foo" {
  name           = "s3-channel"
  s3_bucket_name = aws_s3_bucket.b.bucket
  sns_topic_arn  = aws_sns_topic.config.arn
}

resource "aws_config_configuration_recorder" "foo" {
  name     = "default-recorder"
  role_arn = aws_iam_role.r.arn
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "r" {
  name               = "example-awsconfig"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "p" {
  statement {
    effect  = "Allow"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.b.arn,
      "${aws_s3_bucket.b.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "p" {
  name   = "awsconfig-example"
  role   = aws_iam_role.r.id
  policy = data.aws_iam_policy_document.p.json
}

### Managed Rules ###
resource "aws_config_organization_managed_rule" "dyndb_pitr_enabled" {
  name            = "dynamodb-pitr-enabled"
  rule_identifier = "DYNAMODB_PITR_ENABLED"
}

resource "aws_config_organization_managed_rule" "dynamodb_table_encryption_enabled" {
  name            = "dynamodb-table-encryption-enabled"
  rule_identifier = "DYNAMODB_TABLE_ENCRYPTION_ENABLED"
}

resource "aws_config_organization_managed_rule" "dynamodb_table_encrypted_kms" {
  name            = "dynamodb-table-encrypted-kms"
  rule_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
}

resource "aws_config_organization_managed_rule" "ec2_instance_no_public_ip" {
  name            = "ec2-instance-no-public-ip"
  rule_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
}

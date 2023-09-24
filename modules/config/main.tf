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
  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
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
resource "aws_config_config_rule" "dyndb_pitr_enabled" {
  name = "dynamodb-pitr-enabled"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_PITR_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

resource "aws_config_config_rule" "dynamodb_table_encryption_enabled" {
  name = "dynamodb-table-encryption-enabled"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

resource "aws_config_config_rule" "dynamodb_table_encrypted_kms" {
  name = "dynamodb-table-encrypted-kms"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

resource "aws_config_config_rule" "ec2_instance_no_public_ip" {
  name = "ec2-instance-no-public-ip"

  source {
    owner             = "AWS"
    source_identifier = "EC2_INSTANCE_NO_PUBLIC_IP"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

resource "aws_config_config_rule" "s3_bucket_versioning_enabled" {
  name = "s3-bucket-versioning-enabled"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_VERSIONING_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

resource "aws_config_config_rule" "encrypted_volumes" {
  name = "encrypted-volumes"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

### Lambda ###
resource "aws_config_config_rule" "lambda" {
  name = "CustomLambdaCloudTrail"

  scope {
    compliance_resource_types = ["AWS::CloudTrail::Trail"]
  }

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = var.lambda_arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder.foo
  ]
}

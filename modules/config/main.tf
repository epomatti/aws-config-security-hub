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

### Rule with remediation ####

resource "aws_config_config_rule" "s3_default_encryption_kms" {
  name = "s3-default-encryption-kms"

  source {
    owner             = "AWS"
    source_identifier = "S3_DEFAULT_ENCRYPTION_KMS"
  }

  depends_on = [aws_config_configuration_recorder.foo]
}

resource "aws_config_remediation_configuration" "s3_default_encryption_kms" {
  config_rule_name = aws_config_config_rule.s3_default_encryption_kms.name
  # resource_type    = "AWS::S3::Bucket"
  target_type    = "SSM_DOCUMENT"
  target_id      = "AWS-PublishSNSNotification"
  target_version = "1"


  parameter {
    name         = "AutomationAssumeRole"
    static_value = "arn:aws:iam::875924563244:role/security_config"
  }

  # parameter {
  #   name           = "BucketName"
  #   resource_value = "RESOURCE_ID"
  # }

  parameter {
    name         = "SSEAlgorithm"
    static_value = "AES256"
  }

  # parameter {
  #   name         = "RESOURCE_iD"
  #   static_value = var.topic_arn
  # }

  parameter {
    name           = "TopicArn"
    resource_value = "RESOURCE_ID"
  }

  automatic                  = true
  maximum_automatic_attempts = 10
  retry_attempt_seconds      = 600

  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 25
      error_percentage                     = 20
    }
  }
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

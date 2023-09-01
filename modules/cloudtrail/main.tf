locals {
  trail_name          = "management-events"
  trail_s3_key_prefix = "cloudtrail"
}

# Trail
resource "aws_cloudtrail" "main" {
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.cloudtrail.id
  s3_key_prefix  = local.trail_s3_key_prefix

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.trail.arn}:*" # CloudTrail requires the Log Stream wildcard
  cloud_watch_logs_role_arn  = aws_iam_role.trail.arn

  include_global_service_events = true
  enable_log_file_validation    = true

  kms_key_id = aws_kms_key.cloudtrail.arn

  is_multi_region_trail = false
  is_organization_trail = false

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  insight_selector {
    insight_type = "ApiErrorRateInsight"
  }

  depends_on = [
    aws_kms_key_policy.trail,
    aws_s3_bucket_policy.trail,
  ]
}

### KMS ###
resource "aws_kms_key" "cloudtrail" {
  description         = "CloudTrail trail key"
  multi_region        = false
  enable_key_rotation = false
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

resource "aws_kms_key_policy" "trail" {
  key_id = aws_kms_key.cloudtrail.id

  # For development only; use strict policies for production. 
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "EvandroCustomCloudTrailKMS"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.aws_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "CloudTrailKms"
        Action = "kms:*"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = "*"
      },
    ]
  })
}

### CloudWatch Logs ###
resource "aws_cloudwatch_log_group" "trail" {
  name = "aws-security/cloudtrail"
}

resource "aws_iam_role_policy" "trail" {
  name = "EvandroCustomCloudTrailPolicy"
  role = aws_iam_role.trail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.trail.arn}:*"
      },
    ]
  })
}

resource "aws_iam_role" "trail" {
  name = "EvandroCustomTrailRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      },
    ]
  })
}

### S3 ###
resource "aws_s3_bucket" "cloudtrail" {
  bucket = "bucket-cloudtrail-config-000111xyz"

  force_destroy = true

  tags = {
    Name = "bucket-cloudtrail-config-000111xyz"
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  aws_region     = data.aws_region.current.name
  aws_partition  = data.aws_partition.current.partition
  aws_account_id = data.aws_caller_identity.current.account_id
}

data "aws_iam_policy_document" "s3" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${local.aws_partition}:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.trail_name}"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail.arn}/${local.trail_s3_key_prefix}/AWSLogs/${local.aws_account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${local.aws_partition}:cloudtrail:${local.aws_region}:${local.aws_account_id}:trail/${local.trail_name}"]
    }
  }
}

resource "aws_s3_bucket_policy" "trail" {
  bucket = aws_s3_bucket.cloudtrail.id
  policy = data.aws_iam_policy_document.s3.json
}

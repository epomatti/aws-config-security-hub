terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.12.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

### AWS Config ###

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

resource "aws_config_delivery_channel" "foo" {
  name           = "s3-channel"
  s3_bucket_name = aws_s3_bucket.b.bucket
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

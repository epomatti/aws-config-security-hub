resource "aws_sns_topic" "s3_default_encryption_kms" {
  name = "s3-default-encryption-kms"
}

resource "aws_sns_topic_subscription" "main" {
  topic_arn = aws_sns_topic.s3_default_encryption_kms.arn
  protocol  = "email"
  endpoint  = var.sns_email_destination
}

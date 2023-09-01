resource "aws_s3_bucket" "main" {
  bucket = "bucket-config-sechub-000111"

  force_destroy = true

  tags = {
    Name = "bucket-config-sechub-000111"
  }
}

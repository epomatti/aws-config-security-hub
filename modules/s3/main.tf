resource "aws_s3_bucket" "main" {
  bucket = "s3-config-sechub-12736dcsjak"

  force_destroy = true

  tags = {
    Name = "redshift-bucket"
  }
}

data "aws_region" "current" {}

locals {
  aws_region = data.aws_region.current.name
  az         = "${local.aws_region}a"
}

resource "aws_ebs_volume" "unencrypted" {
  availability_zone = local.az
  size              = 1
  type              = "gp3"
  final_snapshot    = false

  # To trigger alern on AWS Config
  encrypted = false

  tags = {
    Name = "unencrypted-disk"
  }
}

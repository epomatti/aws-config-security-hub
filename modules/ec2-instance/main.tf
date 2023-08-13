locals {
  affix = "mytestbox"
}

resource "aws_iam_instance_profile" "box" {
  name = "test-intance"
  role = aws_iam_role.box.id
}

resource "aws_instance" "box" {
  ami           = "ami-08fdd91d87f63bb09"
  instance_type = "t4g.nano"

  associate_public_ip_address = true
  subnet_id                   = var.subnet
  vpc_security_group_ids      = [aws_security_group.box.id]

  availability_zone    = var.az
  iam_instance_profile = aws_iam_instance_profile.box.id
  user_data            = file("${path.module}/userdata.sh")

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  monitoring    = false
  ebs_optimized = false

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [
      ami,
      associate_public_ip_address,
      user_data
    ]
  }

  tags = {
    Name = "${local.affix}-nat"
  }
}

### IAM Role ###

resource "aws_iam_role" "box" {
  name = "${local.affix}-nat"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "box" {
  role       = aws_iam_role.box.name
  policy_arn = data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn
}

resource "aws_security_group" "box" {
  name        = "ec2-ssm-${local.affix}-nat"
  description = "Controls access for EC2 via Session Manager"
  vpc_id      = var.vpc_id

  tags = {
    Name = "sg-ssm-${local.affix}-nat"
  }
}

resource "aws_security_group_rule" "allow_all_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.box.id
}

resource "aws_security_group_rule" "allow_all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.box.id
}

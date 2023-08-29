resource "aws_iam_user" "user1" {
  name = "User1"
  path = "/terraform-sandbox/"

  force_destroy = true
}

data "aws_iam_policy_document" "user1_ec2_describe" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]
  }
}

resource "aws_iam_user_policy" "lb_ro" {
  name   = "TerraformSandbox-${aws_iam_user.user1.name}"
  user   = aws_iam_user.user1.name
  policy = data.aws_iam_policy_document.user1_ec2_describe.json
}

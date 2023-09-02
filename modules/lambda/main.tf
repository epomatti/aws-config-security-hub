locals {
  filename = "${path.module}/init.zip"
}

resource "aws_lambda_function" "trail" {
  function_name    = "lambda-cloudtrail-config"
  role             = aws_iam_role.lambda.arn
  filename         = local.filename
  source_code_hash = filebase64sha256(local.filename)
  runtime          = "go1.x"
  handler          = "main"

  memory_size = 128
  timeout     = 10

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}

resource "aws_lambda_permission" "config" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.trail.arn
  principal     = "config.amazonaws.com"
  statement_id  = "AllowExecutionFromConfig"
}

resource "aws_iam_role" "lambda" {
  name = "EvandroCustom-CloudTrail-Config-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_basic_exec" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# resource "aws_iam_role_policy_attachment" "trail" {
#   role       = aws_iam_role.lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrail_FullAccess"
# }

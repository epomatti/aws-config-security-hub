terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.17.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "ebs" {
  source = "./modules/ebs"
}

module "dyndb" {
  source = "./modules/dyndb"
}

module "vpc" {
  source = "./modules/vpc"
  region = var.region
}

module "ec2-instance" {
  source = "./modules/ec2-instance"
  vpc_id = module.vpc.vpc_id
  az     = module.vpc.az1
  subnet = module.vpc.subnet_pub1
}

module "s3" {
  source = "./modules/s3"
}

module "iam" {
  source = "./modules/iam"
}

module "cloudtrail" {
  source = "./modules/cloudtrail"
}

module "cloudwatch_logs_metric_filter" {
  source                           = "./modules/cw-metrics"
  cloudtrail_cloudwatch_group_name = module.cloudtrail.trail_cw_group_name
}

module "lambda" {
  source = "./modules/lambda"
}

module "sns" {
  source                = "./modules/sns"
  sns_email_destination = var.sns_email_destination
}

module "config" {
  source     = "./modules/config"
  lambda_arn = module.lambda.arn
  topic_arn  = module.sns.topic_arn

  # Waits on all modules to get the configuration on creation
  depends_on = [
    module.dyndb,
    module.vpc,
    module.ec2-instance,
    module.s3,
    module.cloudtrail,
    module.ebs
  ]
}

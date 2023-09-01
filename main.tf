terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
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

module "config" {
  source = "./modules/config"

  # Waits on all modules to get the configuration on creation
  depends_on = [
    module.dyndb,
    module.vpc,
    module.ec2-instance,
    module.s3,
    module.cloudtrail
  ]
}

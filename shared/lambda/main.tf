provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "aws" {
  profile = var.aws_profile
  region  = "us-east-1"
  alias   = "virginia"
}

terraform {
  backend "s3" {
    region = "ap-northeast-2"
    bucket = "com.example.terraform"
    key    = "lambda.tfstate"
  }
}

module "lambda-edge" {
  source = "terraform-aws-modules/s3-bucket/aws"

  providers = {
    aws = aws.virginia
  }

  bucket = "com.example.lambda-edge"
}

module "lambda" {
  source = "terraform-aws-modules/s3-bucket/aws"
  
  bucket = "com.example.lambda"
}

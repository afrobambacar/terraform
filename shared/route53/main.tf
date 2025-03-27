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
    key    = "route53.tfstate"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    profile = var.aws_profile
    region  = "ap-northeast-2"
    bucket  = "com.example.terraform"
    key     = "vpc.tfstate"
  }
}

data "terraform_remote_state" "ec2" {
  backend = "s3"
  config = {
    profile = var.aws_profile
    region  = "ap-northeast-2"
    bucket  = "com.example.terraform"
    key     = "ec2.tfstate"
  }
}

###################################################################
# Route53 Zones
###################################################################
module "zones" {
  source = "terraform-aws-modules/route53/aws//modules/zones"

  zones = {
    "public_zone" = {
      domain_name = var.domain_name
      comment     = "public zone"
    }

    "private_zone" = {
      domain_name = var.domain_name
      comment     = "private zone"
      vpc = [
        {
          vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
        }
      ]
    }
  }

  tags = {
    ManagedBy = "Terraform"
  }
}

###################################################################
# ACM
###################################################################
module "acm_com" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  domain_name = var.domain_name
  zone_id     = module.zones.route53_zone_zone_id["public_zone"]

  validation_method = "DNS"
  dns_ttl           = 300

  subject_alternative_names = var.subject_alternative_names

  wait_for_validation = false

  tags = {
    Name = var.domian_name
  }
}


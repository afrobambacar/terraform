provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {
    key    = "ssm.tfstate"
    bucket = "com.example.terraform"
    region = "ap-northeast-2"
  }
}

resource "aws_ssm_parameter" "hello_world" {
  name  = "/HELLO_WORLD"
  type  = "String"
  value = var.HELLO_WORLD
}

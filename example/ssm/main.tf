provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_ssm_parameter" "hello_world" {
  name  = "/HELLO_WORLD"
  type  = "String"
  value = var.HELLO_WORLD
}

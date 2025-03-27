provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {
    key    = "ecs/api-main.tfstate"
    bucket = "com.example.terraform"
    region = "ap-northeast-2"
  }
}

module "ecs_cluster" {
  source = "../../modules/ecs-fargate"

  project_name = var.project_name
  stage        = var.stage

  vpc_name                = var.vpc_name
  subnet_names            = var.subnet_names
  route53_zone_name       = var.route53_zone_name
  route53_private_zone    = var.route53_private_zone
  elb_name                = var.elb_name
  security_group_name     = var.security_group_name
  ecs_task_role_name      = var.ecs_task_role_name
  task_excution_role_name = var.task_excution_role_name

  route53_record                = var.route53_record
  target_group                  = var.target_group
  ecs_service                   = var.ecs_service
  ecs_cluster                   = var.ecs_cluster
  ecs_task_definition_family    = var.ecs_task_definition_family
  ecs_task_definition_container = var.ecs_task_definition_container
  ecr_repository                = var.ecr_repository
  host_port                     = var.host_port
  container_port                = var.container_port
}

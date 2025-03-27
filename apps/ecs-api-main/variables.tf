variable "aws_profile" {}
variable "aws_region" {}

# Existing resource variables
variable "vpc_name" {}
variable "subnet_names" {}
variable "route53_zone_name" {}
variable "route53_private_zone" {}
variable "elb_name" {}
variable "security_group_name" {}
variable "ecs_task_role_name" {}
variable "task_excution_role_name" {}

# ECS variables
variable "project_name" {}
variable "stage" {}
variable "route53_record" {}
variable "target_group" {}
variable "ecs_service" {}
variable "ecs_cluster" {}
variable "ecs_task_definition_family" {}
variable "ecs_task_definition_container" {}
variable "ecr_repository" {}
variable "host_port" {}
variable "container_port" {}
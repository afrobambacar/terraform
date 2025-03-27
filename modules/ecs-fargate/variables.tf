variable "project_name" {}
variable "stage" {}

# Existing Resources
variable "vpc_name" {
  type = string
}

variable "subnet_names" {
  type = string
  default = "example-subnet-private*"
}

variable "route53_zone_name" {
  type = string
  default = "example.com."
}

variable "route53_private_zone" {
  type = bool
  default = false
}

variable "elb_name" {
  type = string
  default = "example-internet-facing"
}

variable "security_group_name" {
  type = list(string)
  default = ["example-private-*"]
}

variable "ecs_task_role_name" {
  type = string
  default = "example-ecs-task-role"
}

variable "task_excution_role_name" {
  type = string
  default = "example-ecs-task-execution-role"
}

# ECS variables
variable "route53_record" {}
variable "target_group" {}
variable "ecs_service" {}
variable "ecs_cluster" {}
variable "ecs_task_definition_family" {}
variable "ecs_task_definition_container" {}
variable "ecr_repository" {}
variable "host_port" {}
variable "container_port" {}

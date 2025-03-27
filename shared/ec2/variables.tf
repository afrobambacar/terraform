variable "aws_region" {
  type = string
}

variable "aws_profile" {
  type = string
}

variable "project_name" {
  type = string
}

variable "acm_domain_name" {
  type    = string
  default = "example.com"
}

variable "local_ips" {
  type = string
}
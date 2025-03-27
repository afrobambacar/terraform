variable "aws_profile" {
  type    = string
  default = "default"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project_name" {
  type    = string
  default = "example"
}

variable "domain_name" {
  type    = string
  default = "example.com"
}

variable "acm_subject_alternative_names" {
  type    = list(string)
  default = ["*.example.com", "example.com"]
}
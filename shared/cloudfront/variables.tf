variable "aws_profile" {
  type = string
}

variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

# ACM
variable "route53_zone_name" {
  type    = string
  default = "example.com."
}

variable "route53_domain_name" {
  type    = string
  default = "example.com"
}

variable "route53_cdn_record_name" {
  type    = string
  default = "cdn.example.com"
}

variable "acm_subject_alternative_names" {
  type    = list(string)
  default = ["*.example.com", "example.com"]
}

# S3 Bucket
variable "cdn_bucket_name" {
  type    = string
  default = "com.example.cdn"
}

# CloudFront
variable "lambda_function_name" {
  type    = string
  default = "resize-image"
}

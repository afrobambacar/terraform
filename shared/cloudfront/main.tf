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
    key    = "cloudfront.tfstate"
  }
}

data "aws_route53_zone" "selected" {
  name         = var.route53_zone_name
  private_zone = false
}

###################################################################
# ACM & Route53 
###################################################################
module "acm_com_virginia" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 4.0"

  providers = {
    aws = aws.virginia
  }

  domain_name = var.route53_domain_name
  zone_id     = data.aws_route53_zone.selected.id

  validation_method = "DNS"
  dns_ttl           = 300

  subject_alternative_names = var.acm_subject_alternative_names

  wait_for_validation = false

  tags = {
    Name = "Edge ACM"
  }
}

resource "aws_route53_record" "cdn" {
  zone_id = data.aws_route53_zone.selected.id
  name    = var.route53_cdn_record_name
  type    = "A"

  alias {
    name                   = module.cdn.cloudfront_distribution_domain_name
    zone_id                = module.cdn.cloudfront_distribution_hosted_zone_id
    evaluate_target_health = true
  }
}

###################################################################
# S3 Buckets
###################################################################
module "s3_cdn" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.cdn_bucket_name
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_cdn.s3_bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = module.cdn.cloudfront_origin_access_identity_iam_arns
    }
  }

  statement {
    actions   = ["s3:GetObject"]
    resources = ["${module.s3_cdn.s3_bucket_arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [module.cdn.cloudfront_distribution_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = module.s3_cdn.s3_bucket_id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_s3_bucket_cors_configuration" "example" {
  bucket = module.s3_cdn.s3_bucket_id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

###################################################################
# CloudFront
###################################################################
data "aws_lambda_function" "resize_image" {
  provider = aws.virginia

  function_name = var.lambda_function_name
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  providers = {
    aws = aws.virginia
  }

  aliases = [var.route53_cdn_record_name]

  comment             = "Example CloudFront"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_200"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = true
  origin_access_identities = {
    s3_bucket_one = "Allow access from CloudFront"
  }

  origin = {
    s3_cdn = {
      domain_name = module.s3_cdn.s3_bucket_bucket_regional_domain_name
      s3_origin_config = {
        origin_access_identity = "s3_bucket_one"
      }
    }
  }

  default_cache_behavior = {
    path_pattern           = "*"
    target_origin_id       = "s3_cdn"
    viewer_protocol_policy = "redirect-to-https"
    use_forwarded_values   = false

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    origin_request_policy_id   = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"
    response_headers_policy_id = "60669652-455b-4ae9-85a4-c4c02393f86c"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true
    query_string    = true
  }

  # Lambda@Edge function will use this behavior.
  ordered_cache_behavior = [
    {
      path_pattern           = "/images/*"
      target_origin_id       = "s3_cdn"
      viewer_protocol_policy = "redirect-to-https"

      allowed_methods = ["GET", "HEAD", "OPTIONS"]
      cached_methods  = ["GET", "HEAD"]
      compress        = true
      query_string    = true

      lambda_function_association = {
        origin-response = {
          lambda_arn   = data.aws_lambda_function.resize_image.qualified_arn
          include_body = false
        }
      }
    }
  ]

  viewer_certificate = {
    acm_certificate_arn = module.acm_com_virginia.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  geo_restriction = {
    restriction_type = "whitelist"
    locations        = ["KR"]
  }
}

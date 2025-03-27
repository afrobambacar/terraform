provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {
    key    = "ec2.tfstate"
    bucket = "com.example.terraform"
    region = "ap-northeast-2"
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    profile = var.aws_profile
    bucket  = "com.example.terraform"
    key     = "vpc.tfstate"
    region  = "ap-northeast-2"
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = {
    profile = var.aws_profile
    bucket  = "com.example.terraform"
    key     = "iam.tfstate"
    region  = "ap-northeast-2"
  }
}

data "aws_acm_certificate" "issued" {
  domain   = var.acm_domain_name
  statuses = ["ISSUED"]
}

###################################################################
# Security Groups
###################################################################
module "nat_gateway" {
  source      = "terraform-aws-modules/security-group/aws"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.project_name}-nat-gateway-sg"
  description = "All traffic from private subnet"

  ingress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = var.local_ips
      ipv6_cidr_blocks = "::/0"
      description      = "NET Gateway EIP"
    },
  ]

  egress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
      description      = "Through Internet Gateway"
    }
  ]
}

module "local" {
  source      = "terraform-aws-modules/security-group/aws"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.project_name}-local-sg"
  description = "Security group for the pulbic subnets"

  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      protocol    = "tcp"
      to_port     = 80
      cidr_blocks = var.local_ips
    },
    {
      from_port   = 443
      protocol    = "tcp"
      to_port     = 443
      cidr_blocks = var.local_ips
    }
  ]
  ingress_with_source_security_group_id = []
  egress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
      description      = "Through Internet Gateway"
    }
  ]
  egress_with_source_security_group_id = []
}

module "public" {
  source      = "terraform-aws-modules/security-group/aws"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.project_name}-public-sg"
  description = "Security group for the pulbic subnets"

  ingress_with_cidr_blocks = [
    {
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
      description      = "Accept HTTP"
    },
    {
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
      description      = "Accept HTTPS"
    }
  ]
  ingress_with_source_security_group_id = []
  egress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
      description      = "Through Internet Gateway"
    }
  ]
  egress_with_source_security_group_id = []
}

module "private" {
  source      = "terraform-aws-modules/security-group/aws"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.project_name}-private-sg"
  description = "Security group for the pulbic subnets"
  # dynamic 0 - 65535
  ingress_with_cidr_blocks = []
  ingress_with_source_security_group_id = [
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.local.security_group_id
      description              = "Healthcheck"
    },
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      source_security_group_id = module.public.security_group_id
      description              = "Healthcheck"
    },
  ]
  egress_with_cidr_blocks = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
      description      = "Through the NAT Gateway"
    }
  ]
  egress_with_source_security_group_id = []
}

###################################################################
# Application Load Balancer
###################################################################
resource "aws_alb" "stage" {
  name = "${var.project_name}-internet-facing-stage"
  subnets = [
    data.terraform_remote_state.vpc.outputs.public1_subnet_id,
    data.terraform_remote_state.vpc.outputs.public2_subnet_id
  ]
  load_balancer_type = "application"
  security_groups = [
    module.nat_gateway.security_group_id,
    module.local.security_group_id,
  ]
  internal = false
}

resource "aws_lb_listener" "stage_http" {
  load_balancer_arn = aws_alb.stage.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "stage_https" {
  load_balancer_arn = aws_alb.stage.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "503"
    }
  }
}

resource "aws_alb" "main" {
  name = "${var.project_name}-internet-facing-main"
  subnets = [
    data.terraform_remote_state.vpc.outputs.public1_subnet_id,
    data.terraform_remote_state.vpc.outputs.public2_subnet_id
  ]
  load_balancer_type = "application"
  security_groups = [
    module.nat_gateway.security_group_id,
    module.local.security_group_id,
  ]
  internal = false
}

resource "aws_lb_listener" "main_http" {
  load_balancer_arn = aws_alb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "main_https" {
  load_balancer_arn = aws_alb.main.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "503"
    }
  }
}

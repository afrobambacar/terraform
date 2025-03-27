provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

terraform {
  backend "s3" {
    key    = "vpc.tfstate"
    bucket = "com.example.terraform"
    region = "ap-northeast-2"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# NAT Gateway
resource "aws_eip" "nat_gateway" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-${var.availability_zone1}-eip"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public1.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.project_name}-nat-public1-${var.availability_zone1}"
  }
}

# Default route table
resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    Name = "${var.project_name}-rtb-default"
  }
}

# Default security group
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-sg-default"
  }
}

resource "aws_security_group_rule" "default_ingress_all" {
  type                     = "ingress"
  to_port                  = 0
  protocol                 = "-1"
  from_port                = 0
  security_group_id        = aws_default_security_group.default.id
  source_security_group_id = aws_default_security_group.default.id
}

resource "aws_security_group_rule" "default_egress_all" {
  type              = "egress"
  to_port           = 0
  protocol          = "-1"
  from_port         = 0
  security_group_id = aws_default_security_group.default.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Default network access list
resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
  subnet_ids = [
    aws_subnet.public1.id,
    aws_subnet.public2.id,
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.project_name}-nacl-default"
  }
}

# Subnet
## public1-subnet
resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone1
  cidr_block              = var.cidr_public1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public1-${var.availability_zone1}"
  }
}

## public2-subnet
resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone2
  cidr_block              = var.cidr_public2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public2-${var.availability_zone2}"
  }
}

## private1-subnet
resource "aws_subnet" "private1" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone1
  cidr_block              = var.cidr_private1
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-private1-${var.availability_zone1}"
  }
}

## private2-subnet
resource "aws_subnet" "private2" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone2
  cidr_block              = var.cidr_private2
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.project_name}-subnet-private2-${var.availability_zone2}"
  }
}

# Route table
## public
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-rtb-public"
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

## private1
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-rtb-private1-${var.availability_zone1}"
  }
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private2" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route" "private" {
  route_table_id         = aws_route_table.private.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

# VPC Endpoints for System Manager
resource "aws_vpc_endpoint" "s3" {
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_id       = aws_vpc.vpc.id
  route_table_ids = [
    aws_route_table.private.id,
  ]
  tags = {
    Name = "${var.project_name}-vpce-s3"
  }
}

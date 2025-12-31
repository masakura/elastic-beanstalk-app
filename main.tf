terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  project = "elastic-beanstalk-app"
  tags = {
    Project   = local.project
    ManagedBy = "Terraform"
  }
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, { Name = "${local.project}-vpc" })
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(local.tags, { Name = "${local.project}-internet-gateway" })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = merge(local.tags, { Name = "${local.project}-public-subnet" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(local.tags, { Name = "${local.project}-public-route-table" })
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

resource "aws_iam_role" "aws-elasticbeanstalk-ec2-role" {
  name = "aws-elasticbeanstalk-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "webtier" {
  role       = aws_iam_role.aws-elasticbeanstalk-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "container" {
  role       = aws_iam_role.aws-elasticbeanstalk-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "cloud-watch" {
  role       = aws_iam_role.aws-elasticbeanstalk-ec2-role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "default" {
  name = "${local.project}-profile-default"
  role = aws_iam_role.aws-elasticbeanstalk-ec2-role.name
}

resource "aws_elastic_beanstalk_application" "application" {
  name = "${local.project}-application"

  tags = merge(local.tags, { Name = "${local.project}-application" })
}

resource "aws_elastic_beanstalk_environment" "environment" {
  name                = "${local.project}-environment"
  application         = aws_elastic_beanstalk_application.application.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.7.1 running Node.js 24"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.public.id
  }

  setting {
    namespace = "aws:ec2:instances"
    name      = "InstanceTypes"
    value     = "t3.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.default.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:container:nodejs"
    name      = "NodeCommand"
    value     = "npm start"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NPM_USE_PRODUCTION"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "IgnoreHealthCheck"
    value     = "true"
  }

  depends_on = [
    aws_iam_instance_profile.default
  ]
}

output "eb_endpoint_url" {
  value = aws_elastic_beanstalk_environment.environment.endpoint_url
}

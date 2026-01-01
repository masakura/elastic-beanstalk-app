variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_id" {
  type = string
}

variable "application_name" {
  type = string
}

resource "aws_iam_role" "aws-elasticbeanstalk-ec2-role" {
  name = "${var.project}-${var.env}-ec2-role"
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
  name = "${var.project}-${var.env}-profile-default"
  role = aws_iam_role.aws-elasticbeanstalk-ec2-role.name
}

resource "aws_elastic_beanstalk_environment" "environment" {
  name                = "${var.project}-${var.env}-env"
  application         = var.application_name
  solution_stack_name = "64bit Amazon Linux 2023 v6.7.1 running Node.js 24"

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = var.public_subnet_id
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

output "elastic_beanstalk_endpoint_url" {
  value = aws_elastic_beanstalk_environment.environment.endpoint_url
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.environment.name
}

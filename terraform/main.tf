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
  envs    = ["production", "staging", "master"]
}

module "network" {
  source = "./modules/network"

  project = local.project
}

module "elastic_beanstalk_application" {
  source = "./modules/elastic_beanstalk/application"

  project = local.project
}

module "elastic_beanstalk_environment" {
  for_each = toset(local.envs)
  source   = "./modules/elastic_beanstalk/environment"

  project          = local.project
  env              = each.key
  application_name = module.elastic_beanstalk_application.application_name
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
}

module "iam" {
  source = "./modules/iam"
}

output "eb_endpoint_urls" {
  value = { for k, v in module.elastic_beanstalk_environment : k => v.elastic_beanstalk_endpoint_url }
}

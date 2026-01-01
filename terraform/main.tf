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
}

module "network" {
  source = "./modules/network"

  project = local.project
}

module "elastic_beanstalk" {
  source = "./modules/elastic_beanstalk"

  project          = local.project
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
}

module "iam" {
  source = "./modules/iam"
}

output "eb_endpoint_url" {
  value = module.elastic_beanstalk.eb_endpoint_url
}

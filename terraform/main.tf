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

module "network" {
  source = "./modules/network"

  project = local.project
  tags    = local.tags
}

module "elastic_beanstalk" {
  source = "./modules/elastic_beanstalk"

  project          = local.project
  tags             = local.tags
  vpc_id           = module.network.vpc_id
  public_subnet_id = module.network.public_subnet_id
}

output "eb_endpoint_url" {
  value = module.elastic_beanstalk.eb_endpoint_url
}

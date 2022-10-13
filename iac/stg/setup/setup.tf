terraform {
  backend "s3" {
    bucket         = "terraform-state-storage-863362256468"
    dynamodb_table = "terraform-state-lock-863362256468"
    key            = "sg738-fav-color/stg/setup.tfstate"
    region         = "us-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

module "setup" {
  source = "../../modules/setup"
  env    = "stg"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.8.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }
  }

  cloud {
    organization = "hc-implementation-services"

    workspaces {
      name = "accelerator-aws-vault"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "tls" {}

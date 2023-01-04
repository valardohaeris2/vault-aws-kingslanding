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
    local = {
      source = "hashicorp/local"
      version = "~> 2"
    }
  }

  cloud {
    organization = "ashleyconner"

    workspaces {
      name = "vault-aws-kingslanding"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

provider "tls" {}

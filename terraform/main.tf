terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"
  default_tags {
    tags = {
      Environment = "Dev"
      Name        = "okperez"
      Service     = "aws-devops-lab"
    }
  }
}

terraform {
  backend "s3" {
    bucket       = "terraform-state-storage-2026"
    key          = "terraform/terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true
  }
}

locals {
  aws_bucket     = "BUCKET_NAME"
  aws_region     = "BUCKET_REGION"
  aws_access_key = "BUCKET_ACCESS_KEY"
  aws_secret_key = "BUCKET_SECRET_KEY"
  project_name   = "2020-election-scraper"
  project_tags = {
    project = "2020-election-scraper"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket     = "BUCKET_NAME"
    key        = "BUCKET_FILE_KEY"
    region     = "BUCKET_REGION"
    access_key = "BUCKET_ACCESS_KEY"
    secret_key = "BUCKET_SECRET_KEY"
  }
}

provider "aws" {
  region = local.aws_region
}

terraform {
  required_version = ">= 0.12.0"
  backend "s3" {
    bucket  = "tfstate-ng46"
    region  = "us-east-1"
    key     = "terraform.tfstate"
    encrypt = true
  }
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region     = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tfstate-ng46"
  versioning {
    enabled = true
  }
}

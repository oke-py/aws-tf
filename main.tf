terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket  = "outside-code-management"
    region  = "ap-northeast-1"
    key     = "infra.state"
    encrypt = true
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
  feature_set = "ALL"
}

resource "aws_guardduty_organization_admin_account" "root" {
  depends_on = [aws_organizations_organization.org]

  admin_account_id = var.org_admin_id
}

module "virginia" {
  source = "./modules/aws/guardduty"
  providers = {
    aws = aws.Virginia
  }
  aws_account_id      = var.org_admin_id
  slack_aws_alert_url = var.slack_aws_alert_url

  depends_on = [aws_guardduty_organization_admin_account.root]
}

module "tokyo" {
  source = "./modules/aws/guardduty"
  providers = {
    aws = aws.Tokyo
  }
  aws_account_id      = var.org_admin_id
  slack_aws_alert_url = var.slack_aws_alert_url

  depends_on = [aws_guardduty_organization_admin_account.root]
}

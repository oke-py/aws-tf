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
variable "org_admin_id" {}
variable "org_account1_id" {}
variable "slack_aws_alert_url" {}

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

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY"
  ]
  feature_set = "ALL"
}

resource "aws_organizations_policy" "scp_restrict_region" {
  name = "deny except for Tokyo region"

  content = <<CONTENT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyExceptForTokyo",
      "Effect": "Deny",
      "NotAction": [
        "a4b:*", "artifact:*", "aws-portal:*",
        "budgets:*",
        "ce:*", "chime:*", "cloudfront:*", "cur:*",
        "datapipeline:GetAccountLimits", "directconnect:",
        "globalaccelerator:*",
        "health:*",
        "iam:*", "importexport:*",
        "mobileanalytics:*",
        "organizations:*",
        "resource-groups:*", "route53:*", "route53domains:*",
        "s3:GetBucketLocation", "s3:ListAllMyBuckets", "shield:*", "support:*",
        "tag:*", "trustedadvisor:*",
        "waf:*",
        "wellarchitected:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "ap-northeast-1"
          ]
        }
      }
    }
  ]
}
CONTENT
}

resource "aws_organizations_policy_attachment" "account" {
  policy_id = aws_organizations_policy.scp_restrict_region.id
  target_id = var.org_account1_id
}

resource "aws_organizations_organizational_unit" "dev" {
  name      = "dev"
  parent_id = aws_organizations_organization.org.roots[0].id
}

module "virginia" {
  source = "./modules/aws/guardduty"
  providers = {
    aws = aws.Virginia
  }
  aws_account_id      = var.org_admin_id
  slack_aws_alert_url = var.slack_aws_alert_url
}

module "tokyo" {
  source = "./modules/aws/guardduty"
  providers = {
    aws = aws.Tokyo
  }
  aws_account_id      = var.org_admin_id
  slack_aws_alert_url = var.slack_aws_alert_url
}

resource "aws_guardduty_organization_admin_account" "root" {
  depends_on = [aws_organizations_organization.org]

  admin_account_id = var.org_admin_id
}

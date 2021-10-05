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
    "config.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
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
            "us-east-1",
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

resource "aws_config_aggregate_authorization" "organization" {
  account_id = var.org_admin_id
  region     = "ap-northeast-1"
}

resource "aws_config_conformance_pack" "organization" {
  name               = "my-rule"
  delivery_s3_bucket = aws_s3_bucket.delivery.bucket

  input_parameter {
    parameter_name  = "AccessKeysRotatedParameterMaxAccessKeyAge"
    parameter_value = "90"
  }

  template_body = <<EOT
Resources:
  IamRootAccessKeyCheck:
    Properties:
      ConfigRuleName: iam-root-access-key-check
      Source:
        Owner: AWS
        SourceIdentifier: IAM_ROOT_ACCESS_KEY_CHECK
    Type: AWS::Config::ConfigRule
EOT

  depends_on = [
    aws_config_configuration_recorder.organization,
    aws_s3_bucket.delivery
  ]
}

resource "aws_config_configuration_aggregator" "organization" {
  depends_on = [aws_iam_role_policy_attachment.organization]

  name = "my-config-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.organization.arn
  }
}

resource "aws_iam_role" "aggregator" {
  name = "awsconfig-aggregator"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "organization" {
  role       = aws_iam_role.organization.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_s3_bucket" "delivery" {
  bucket = "awsconfigconforms-my-rule"
  acl    = "private"

  lifecycle_rule {
    enabled = true
    transition {
      days          = "366"
      storage_class = "GLACIER"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = "aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }
}

resource "aws_config_configuration_recorder" "organization" {
  name     = "my-recorder"
  role_arn = aws_iam_role.recorder.arn
}

resource "aws_iam_role" "recorder" {
  name = "awsconfig-recorder"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

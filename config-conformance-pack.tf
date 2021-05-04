resource "aws_config_aggregate_authorization" "organization" {
  provider   = aws.Tokyo
  account_id = var.org_admin_id
  region     = "ap-northeast-1"
}

resource "aws_config_conformance_pack" "organization" {
  provider           = aws.Tokyo
  name               = "my-rule"
  delivery_s3_bucket = aws_s3_bucket.delivery.bucket

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
  depends_on = [aws_iam_role_policy_attachment.aggregator]

  provider = aws.Tokyo
  name     = "my-config-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.aggregator.arn
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

resource "aws_iam_role_policy_attachment" "aggregator" {
  provider   = aws.Tokyo
  role       = aws_iam_role.aggregator.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}

resource "aws_s3_bucket" "delivery" {
  provider = aws.Tokyo
  bucket   = "awsconfigconforms-my-rule"
  acl      = "private"

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

data "aws_iam_policy_document" "config-bucket-policy" {
  version = "2012-10-17"
  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      aws_s3_bucket.delivery.arn
    ]
  }
  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.delivery.arn
    ]
  }
  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.delivery.arn}/AWSLogs/${data.aws_caller_identity.self.account_id}/Config/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "delivery" {
  provider = aws.Tokyo
  bucket   = aws_s3_bucket.delivery.bucket
  policy   = data.aws_iam_policy_document.config-bucket-policy.json
}

resource "aws_config_configuration_recorder" "organization" {
  provider = aws.Tokyo
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

resource "aws_config_configuration_recorder_status" "organization" {
  provider   = aws.Tokyo
  name       = aws_config_configuration_recorder.organization.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.organization]
}

resource "aws_config_delivery_channel" "organization" {
  provider       = aws.Tokyo
  name           = "my-config-delivery"
  s3_bucket_name = aws_s3_bucket.delivery.bucket
}

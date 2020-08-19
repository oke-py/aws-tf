########################################
# S3
########################################

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
      "${aws_s3_bucket.config-bucket.arn}"
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
      "${aws_s3_bucket.config-bucket.arn}"
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
      "${aws_s3_bucket.config-bucket.arn}/AWSLogs/${data.aws_caller_identity.self.account_id}/Config/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket" "config-bucket" {
  bucket = "sec-config-ng46"
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

resource "aws_s3_bucket_policy" "config" {
  bucket = aws_s3_bucket.config-bucket.bucket
  policy = data.aws_iam_policy_document.config-bucket-policy.json
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config-bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

########################################
# AWS Config
########################################

module "config-virginia" {
  source = "./modules/aws/config"
  providers = {
    aws = aws.Virginia
  }
  bucket = aws_s3_bucket.config-bucket.bucket
  region = "us-east-1"
}

module "config-tokyo" {
  source = "./modules/aws/config"
  providers = {
    aws = aws.Tokyo
  }
  bucket = aws_s3_bucket.config-bucket.bucket
  region = "ap-northeast-1"
}

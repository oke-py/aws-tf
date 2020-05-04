data "aws_caller_identity" "self" {}

data "aws_iam_policy_document" "cloudtrail-bucket-policy" {
  version = "2012-10-17"
  statement {
    sid    = "AWSCloudTrailAclCheck20150319"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = [
      "${aws_s3_bucket.cloudtrail-bucket.arn}"
    ]
  }
  statement {
    sid    = "AWSCloudTrailWrite20150319"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.cloudtrail-bucket.arn}/AWSLogs/${data.aws_caller_identity.self.account_id}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket" "cloudtrail-bucket" {
  bucket = "sec-cloudtrail-ng46"
  acl    = "private"
  region = "us-east-1"

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

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail-bucket.bucket
  policy = data.aws_iam_policy_document.cloudtrail-bucket-policy.json
}

resource "aws_cloudwatch_log_group" "cloudtrail-log" {
  name = "/aws/cloudtrail"
}

resource "aws_cloudtrail" "sec-cloudtrail" {
  name                          = "sec-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail-bucket.bucket
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.cloudtrail-log.arn
  cloud_watch_logs_role_arn     = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:role/CloudTrail_CloudWatchLogs_Role"
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true
}

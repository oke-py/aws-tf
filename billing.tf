########################################
# AWS Budgets
########################################

resource "aws_budgets_budget" "cost" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "30.0"
  limit_unit        = "USD"
  time_period_start = "2020-05-01_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["okepy.naoki@gmail.com"]
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
  }
}

########################################
# Cost & Usage Reports
########################################

data "aws_iam_policy_document" "s3bucket-policy" {
  version = "2008-10-17"
  statement {
    sid    = "Stmt1"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketPolicy",
      "s3:GetBucketAcl"
    ]
    resources = [
      "${aws_s3_bucket.cost-report.arn}"
    ]
  }
  statement {
    sid    = "Stmt2"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["billingreports.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.cost-report.arn}/*"
    ]
  }
}

resource "aws_s3_bucket" "cost-report" {
  bucket        = "sec-cur-ng46"
  acl           = "private"
  force_destroy = "false"
  region        = "us-east-1"
}

resource "aws_s3_bucket_policy" "cost-report" {
  bucket = aws_s3_bucket.cost-report.bucket
  policy = data.aws_iam_policy_document.s3bucket-policy.json
}

resource "aws_cur_report_definition" "cost-report" {
  report_name                = "sec-cur"
  compression                = "GZIP"
  format                     = "textORcsv"
  s3_bucket                  = aws_s3_bucket.cost-report.bucket
  s3_region                  = aws_s3_bucket.cost-report.region
  time_unit                  = "HOURLY"
  additional_schema_elements = ["RESOURCES"]
  additional_artifacts       = ["REDSHIFT", "QUICKSIGHT"]
}

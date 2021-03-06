variable "aws_account_id" {}
variable "slack_aws_alert_url" {}

resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

resource "aws_guardduty_organization_configuration" "org-gd" {
  auto_enable = true
  detector_id = aws_guardduty_detector.guardduty.id
}

resource "aws_cloudformation_stack" "amazon-guardduty-to-slack" {
  name = "amazon-guardduty-to-slack"
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    IncomingWebHookURL = var.slack_aws_alert_url
    SlackChannel = "#alert-aws"
    MinSeverityLevel = "LOW"
  }
  template_url = "https://tfstate-ng46.s3.amazonaws.com/gd2slack.template"
}

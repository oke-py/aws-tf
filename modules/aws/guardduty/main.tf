resource "aws_guardduty_detector" "guardduty" {
  enable = true
}

resource "aws_cloudformation_stack" "amazon-guardduty-to-slack" {
  name = "amazon-guardduty-to-slack"
  capabilities = ["CAPABILITY_IAM"]
  parameters = {
    IncomingWebHookURL = var.slack_aws_alert_url
    SlackChannel = "#alert-aws"
    MinSeverityLevel = "LOW"
  }
  template_url = "https://outside-code-management.s3.ap-northeast-1.amazonaws.com/gd2slack.template"
}

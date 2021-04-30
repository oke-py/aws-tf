# See https://github.com/hgsgtk/tf-guardduty

resource "aws_cloudwatch_event_rule" "guardduty" {
  name        = "capture-guardduty"
  description = "Capture GuardDuty finding events"

  event_pattern = <<EOF
{
  "source": [
    "aws.guardduty"
  ],
  "detail-type": [
    "GuardDuty Finding"
  ]
}
EOF
}

resource "aws_cloudwatch_event_target" "guardduty_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty.id
  target_id = "guardduty-sns"
  arn       = aws_sns_topic.event_bridge_from_guardduty.arn
}

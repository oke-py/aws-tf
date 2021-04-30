# See https://github.com/hgsgtk/tf-guardduty

resource "aws_sns_topic" "event_bridge_from_guardduty" {
  name              = "event-bridge-from-guardduty"
  kms_master_key_id = aws_kms_key.for_encrypt_sns_topic.key_id
}

resource "aws_sns_topic_policy" "event_bridge_from_guardduty_policy" {
  arn = aws_sns_topic.event_bridge_from_guardduty.arn

  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  version = "2012-10-17"

  statement {
    sid    = "__default_statement_ID"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]

    resources = [
      aws_sns_topic.event_bridge_from_guardduty.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        var.aws_account_id
      ]
    }
  }

  statement {
    sid    = "allow_AWSEvents_publish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sns:Publish",
    ]

    resources = [
      aws_sns_topic.event_bridge_from_guardduty.arn,
    ]
  }
}

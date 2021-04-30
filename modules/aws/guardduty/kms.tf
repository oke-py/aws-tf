# See https://github.com/hgsgtk/tf-guardduty

resource "aws_kms_key" "for_encrypt_sns_topic" {
  description         = "encrypt sns topic of guardduty"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.policy_for_encrypt_sns_topic.json
}


resource "aws_kms_alias" "for_encrypt_sns_topic_alias" {
  name          = "alias/guardduty/for_encrypt_sns_topic"
  target_key_id = aws_kms_key.for_encrypt_sns_topic.key_id
}


data "aws_iam_policy_document" "policy_for_encrypt_sns_topic" {
  version = "2012-10-17"

  statement {
    sid    = "Enable Root User Permissions"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid    = "AWSEvents"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "*",
    ]
  }
}

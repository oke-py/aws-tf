variable bucket {}
variable region {}

data "aws_caller_identity" "self" {}

resource "aws_config_delivery_channel" "config-dc" {
  name           = "aws-config-${var.region}"
  s3_bucket_name = var.bucket
  depends_on     = [aws_config_configuration_recorder.config-rec]
}

resource "aws_config_configuration_recorder" "config-rec" {
  name     = "aws-config-${var.region}"
  role_arn = "arn:aws:iam::${data.aws_caller_identity.self.account_id}:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"
  recording_group {
    include_global_resource_types = var.region == "us-east-1" ? true : false
  }
}

resource "aws_config_configuration_recorder_status" "config-rec-status" {
  name       = aws_config_configuration_recorder.config-rec.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.config-dc]
}

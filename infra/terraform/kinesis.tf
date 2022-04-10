data "aws_iam_policy_document" "kinesis_data_firehose" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}/*"
    ]
  }
}

module "kinesis_data_firehose_role" {
  source = "./iam_role"
  name   = "kinesis-data-firehose"
  identifier = "firehose.amazonaws.com"
  policy     = data.aws_iam_policy_document.kinesis_data_firehose.json
}

data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:ap-northeast-1:*:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::*:role/cloudwatch-logs"]
  }
}

module "cloudwatch_logs_role" {
  source = "./iam_role"
  name   = "cloudwatch-logs"
  identifier = "logs.ap-northeast-1.amazonaws.com"
  policy     = data.aws_iam_policy_document.cloudwatch_logs.json
}

resource "aws_cloudwatch_log_subscription_filter" "practice_terrafrom_kinesis_filter" {
  name           = "practice-terrafrom-kinesis-filter"
  log_group_name = aws_cloudwatch_log_group.for_ecs_scheduled_tasks.name
  destination_arn = aws_kinesis_firehose_delivery_stream.practice_terrafrom_kinesis.arn
  filter_pattern = "[]"
  role_arn       = module.cloudwatch_logs_role.iam_role_arn
}
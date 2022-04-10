resource "aws_s3_bucket" "private" {
  bucket = "private-dodonki-practice-terraform"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "private" {
  bucket                  = aws_s3_bucket.private.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "public" {
  bucket = "public-dodonki-practice-terraform"
  acl = "public-read"

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-dodonki-practice-terraform"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log.json
}

data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}

resource "aws_s3_bucket" "artifact" {
  bucket        = "practice-terrafrom-artifact"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket" "operation" {
  bucket        = "practice-terrafrom-operation"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket" "athena_query_results" {
  bucket        = "athena-query-results-practice-terrafrom"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_s3_bucket" "cloudwatch_logs" {
  bucket        = "cloudwatch-logs-dodonki-pragmatic-terraform"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = "180"
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "practice_terrafrom_kinesis" {
  name        = "practice-terrafrom-kinesis"
  destination = "s3"

  s3_configuration {
    role_arn   = module.kinesis_data_firehose_role.iam_role_arn
    bucket_arn = aws_s3_bucket.cloudwatch_logs.arn
    prefix     = "ecs-scheduled-tasks/practice-terrafrom-kinesis/"
  }
}
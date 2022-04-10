resource "aws_ssm_parameter" "db_username" {
  name        = "/db/username"
  value       = "root"
  type        = "String"
  description = ""
}

resource "aws_ssm_parameter" "db_raw_password" {
  name        = "/db/password"
  value       = "VeryStrongPassword!"
  type        = "SecureString"
  description = ""

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_document" "session_manager_run_shell" {
  name = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<EOF
    {
        "schemaVersion": "1.0",
        "description": "Document to hold regional settings for Session Manager",
        "sessionType": "Standard_Stream",
        "inputs": {
            "s3BucketName": "${aws_s3_bucket.operation.id}",
            "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation.name}"
        }
    }
EOF
}
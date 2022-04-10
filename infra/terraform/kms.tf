resource "aws_kms_key" "practice_terrafrom_kms" {
  description = ""
  enable_key_rotation = true
  is_enabled = true
  deletion_window_in_days = 20
}

resource "aws_kms_alias" "practice_terrafrom_kms" {
  name          = "alias/practice_terrafrom_kms"
  target_key_id = aws_kms_key.practice_terrafrom_kms.key_id
}
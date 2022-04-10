resource "aws_ecr_repository" "practice_terrafrom_ecr" {
  name = "practice-terrafrom-ecr"
}

resource "aws_ecr_lifecycle_policy" "practice_terrafrom_ecr_lcp" {
  repository = aws_ecr_repository.practice_terrafrom_ecr.name

  policy = <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last 30 release tagged images",
                "selection": {
                    "tagStatus": "tagged",
                    "tagPrefixList": ["release"],
                    "countType": "imageCountMoreThan",
                    "countNumber": 30
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
EOF
}
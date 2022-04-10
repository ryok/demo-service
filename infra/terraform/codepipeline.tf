data "aws_iam_policy_document" "codepipeline" {
  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObjectAcl",
      "s3:PutObject",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codestar-connections:UseConnection",
      "ecs:DescribeServices",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeTasks",
      "ecs:ListTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "iam:PassRole",
    ]
  }
}

module "codepipeline_role" {
  source     = "./iam_role"
  name       = "codepipeline"
  identifier = "codepipeline.amazonaws.com"
  policy     = data.aws_iam_policy_document.codepipeline.json
}

resource "aws_codepipeline" "practice_terrafrom_cp" {
  name     = "practice-terrafrom-cp"
  role_arn = module.codepipeline_role.iam_role_arn

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.practice_terrafrom_github.arn
        FullRepositoryId = "dodonki1223/practice-terraform04-16"
        BranchName       = "main"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.practice_terrafrom_cb_p.id
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.practice_terrafrom_ecs.name
        ServiceName = aws_ecs_service.practice_terrafrom_ecs_service.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  artifact_store {
    location = aws_s3_bucket.artifact.id
    type     = "S3"
  }
}

resource "aws_codestarconnections_connection" "practice_terrafrom_github" {
  name          = "practice-terrafrom-github"
  provider_type = "GitHub"
}

locals {
  webhook_secret = ""
}

resource "aws_codepipeline_webhook" "practice_terrafrom_cp_webhook" {
  name = "practice-terrafrom-cp-webhook"
  target_pipeline = aws_codepipeline.practice_terrafrom_cp.name
  target_action   = "Source"
  authentication = "GITHUB_HMAC"

  authentication_configuration {
    secret_token = local.webhook_secret
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

resource "github_repository_webhook" "practice_terrafrom_grw" {
  repository = "practice-terraform04-16"

  configuration {
    url          = aws_codepipeline_webhook.practice_terrafrom_cp_webhook.url
    secret       = local.webhook_secret
    content_type = "json"
    insecure_ssl = false
  }

  events = ["push"]
}
resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name              = "/ecs-scheduled-tasks/practice_terrafrom"
  retention_in_days = 180
}

resource "aws_ecs_task_definition" "practice_terrafrom_batch" {
  family                   = "practice-terrafrom-batch"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./batch_container_definition.json")
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn
}

module "ecs_events_role" {
  source     = "./iam_role"
  name       = "ecs-events"
  identifier = "events.amazonaws.com"
  policy     = data.aws_iam_policy.ecs_events_role_policy.policy
}

data "aws_iam_policy" "ecs_events_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

resource "aws_cloudwatch_event_rule" "practice_terrafrom_batch" {
  name        = "practice-terrafrom-batch"
  description = ""
  schedule_expression = "cron(*/2 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "practice_terrafrom_batch" {
  target_id = "practice-terrafrom-batch"
  rule = aws_cloudwatch_event_rule.practice_terrafrom_batch.name
  role_arn = module.ecs_events_role.iam_role_arn
  arn = aws_ecs_cluster.practice_terrafrom_ecs.arn

  ecs_target {
    launch_type         = "FARGATE"
    task_count          = 1
    platform_version    = "1.3.0"
    task_definition_arn = aws_ecs_task_definition.practice_terrafrom_batch.arn

    network_configuration {
      assign_public_ip = "false"
      subnets          = [aws_subnet.practice_terrafrom_private_subnet_1a.id]
    }
  }
}
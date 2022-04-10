resource "aws_ecs_cluster" "practice_terrafrom_ecs" {
  name = "practice-terrafrom-ecs"
}

resource "aws_ecs_task_definition" "practice_terrafrom_ecs_task" {
  family = "practice-terrafrom"
  cpu    = "256"
  memory = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = file("./container_definitions.json")
  execution_role_arn    = module.ecs_task_execution_role.iam_role_arn
}

resource "aws_ecs_service" "practice_terrafrom_ecs_service" {
  name            = "practice-terrafrom-ecs-service"
  cluster         = aws_ecs_cluster.practice_terrafrom_ecs.arn
  task_definition = aws_ecs_task_definition.practice_terrafrom_ecs_task.arn
  desired_count = 2
  launch_type   = "FARGATE"
  platform_version = "1.3.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.practice_terrafrom_private_subnet_1a.id,
      aws_subnet.practice_terrafrom_private_subnet_1c.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.practice_terrafrom_tg.arn
    container_name   = "practice-terrafrom"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.practice_terrafrom_vpc.id
  port        = 80
  cidr_blocks = [aws_vpc.practice_terrafrom_vpc.cidr_block]
}

resource "aws_cloudwatch_log_group" "practice_terrafrom_for_ecs" {
  name = "/ecs/practice_terrafrom"
  retention_in_days = 180
}

data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "ecs_task_execution" {
  source_json = data.aws_iam_policy.ecs_task_execution_role_policy.policy

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "ecs_task_execution_role" {
  source = "./iam_role"
  name   = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}
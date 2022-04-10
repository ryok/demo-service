resource "aws_lb" "practice_terrafrom_alb" {
  name = "practice-terrafrom-alb"
  load_balancer_type = "application"
  internal = false
  idle_timeout = 60

  subnets = [
    aws_subnet.practice_terrafrom_public_subnet_1a.id,
    aws_subnet.practice_terrafrom_public_subnet_1c.id
  ]

  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id,
  ]
}

module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.practice_terrafrom_vpc.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.practice_terrafrom_vpc.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "http_redirect_sg"
  vpc_id      = aws_vpc.practice_terrafrom_vpc.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.practice_terrafrom_alb.arn
  port              = "80"
  protocol = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは『HTTP』です"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.practice_terrafrom_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn = aws_acm_certificate.dodonki.arn
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = ""
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.practice_terrafrom_alb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "practice_terrafrom_tg" {
  name = "practice-terrafrom-tg"
  target_type = "ip"
  vpc_id   = aws_vpc.practice_terrafrom_vpc.id
  port     = 80
  protocol = "HTTP"
  deregistration_delay = 300

  health_check {
    path = "/"
    healthy_threshold = 5
    unhealthy_threshold = 2
    timeout = 5
    interval = 30
    matcher = 200
    port = "traffic-port"
    protocol = "HTTP"
  }

  depends_on = [aws_lb.practice_terrafrom_alb]
}

resource "aws_lb_listener_rule" "practice_terrafrom_lr" {
  listener_arn = aws_lb_listener.https.arn
  priority = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.practice_terrafrom_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

data "aws_route53_zone" "dodonki" {
  name = "dodonki.com"
}

resource "aws_route53_zone" "test_dodonki" {
  name = "test.dodonki.com"
}

resource "aws_route53_record" "dodonki" {
  zone_id = data.aws_route53_zone.dodonki.zone_id
  name    = data.aws_route53_zone.dodonki.name
  type = "A"

  alias {
    name                   = aws_lb.practice_terrafrom_alb.dns_name
    zone_id                = aws_lb.practice_terrafrom_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dodonki_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.dodonki.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = data.aws_route53_zone.dodonki.id
  ttl     = 60
}

resource "aws_acm_certificate" "dodonki" {
  domain_name = aws_route53_record.dodonki.name
  subject_alternative_names = []
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "dodonki" {
  certificate_arn = aws_acm_certificate.dodonki.arn
  validation_record_fqdns = [for record in aws_route53_record.dodonki_certificate : record.fqdn]
}

output "alb_dns_name" {
  value = aws_lb.practice_terrafrom_alb.dns_name
}

output "domain_name" {
  value = aws_route53_record.dodonki.name
}
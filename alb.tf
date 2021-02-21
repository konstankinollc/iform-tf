resource "aws_lb" "iform" {
  name               = "iform-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.loadbalancer.id]

  subnets = [
    aws_subnet.prod-subnet-public.id,
    aws_subnet.prod-subnet-public-2.id
  ]

  enable_deletion_protection = false

  # TODO: store access logs at some point
  #
  #   access_logs {
  #     bucket  = aws_s3_bucket.lb_logs.bucket
  #     prefix  = "test-lb"
  #     enabled = true
  #   }

  tags = {
    Name = "iForm Load Balancer"
  }
}

resource "aws_lb_target_group_attachment" "iform" {
  target_group_arn = aws_lb_target_group.iform.arn
  target_id        = aws_instance.app.id
  port             = 80
}

resource "aws_lb_target_group" "iform" {
  name        = "iform-lb-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.prod-vpc.id
  target_type = "instance"

  tags = {
    Name = "iForm Target Group"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.iform.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.CERTIFICATE_ARN

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.iform.arn
  }
}

resource "aws_alb_listener" "http" {

  load_balancer_arn = aws_lb.iform.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# output "loadbalancer" {
#   value = aws_lb.iform.dns_name
# }

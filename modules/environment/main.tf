#Creating stage lb
resource "aws_lb" "stage-lb" {
  name = var.stage-lb-tag
  internal = false
  load_balancer_type = "application"
  security_groups = var.lb-sg
  subnets = var.lb-subnet
  enable_deletion_protection = false
  tags = {
    Name = var.stage-lb-tag
  }
}

#Creating stage target group
resource "aws_lb_target_group" "stage-tg" {
  name = var.stage-tg-tag
  port = 30001
  protocol = "HTTP"
  vpc_id = var.vpc-id

  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
  }
}

#Creating target group attachment worker
resource "aws_lb_target_group_attachment" "stage-tg-att" {
  target_group_arn = aws_lb_target_group.stage-tg.arn
  target_id = element(split(",", join(",", "${var.instance}")),count.index)
  port = 30001
  count = 3
}

#Creating load balancer listener for http
resource "aws_lb_listener" "stage-http" {
  load_balancer_arn = aws_lb.stage-lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    # type = "forward"
    # target_group_arn = aws_lb_target_group.stage-tg.arn
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTPS_301"
    }
  }
}

#Creating load balancer listener for https
resource "aws_lb_listener" "stage-https" {
  load_balancer_arn = aws_lb.stage-lb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.stage-tg.arn
  }
}

#Creating prod lb
resource "aws_lb" "prod-lb" {
  name = var.prod-alb-tag
  internal = false
  load_balancer_type = "application"
  security_groups = var.lb-sg
  subnets = var.lb-subnet
  enable_deletion_protection = false
  tags = {
    Name = var.prod-alb-tag
  }
}

#Creating prod target group
resource "aws_lb_target_group" "prod-tg" {
  name = var.prod-tg-tag
  port = 30002
  protocol = "HTTP"
  vpc_id = var.vpc-id

  health_check {
    interval = 30
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
  }
}

#Creating target group attachment workernode
resource "aws_lb_target_group_attachment" "prod-tg-att" {
  target_group_arn = aws_lb_target_group.prod-tg.arn
  target_id = element(split(",", join(",", "${var.instance}")),count.index)
  port = 30002
  count = 3
}

#Creating load balancer listener for http
resource "aws_lb_listener" "prod-http" {
  load_balancer_arn = aws_lb.prod-lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    # type = "forward"
    # target_group_arn = aws_lb_target_group.prod-tg.arn
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTPS_301"
    }
  }
}

#Creating load balancer listener for https
resource "aws_lb_listener" "prod-https" {
  load_balancer_arn = aws_lb.prod-lb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prod-tg.arn
  }
}

#Creating prod lb
resource "aws_lb" "grafana-lb" {
  name = var.grafana-lb-tag
  internal = false
  load_balancer_type = "application"
  security_groups = var.kube-sg
  subnets = var.kube-subnet
  enable_deletion_protection = false
  tags = {
    Name = var.grafana-lb-tag
  }
}

#Creating prod target group
resource "aws_lb_target_group" "grafana-tg" {
  name = var.grafana-tg-tag
  port = 31300
  protocol = "HTTP"
  vpc_id = var.vpc-id

  health_check {
    interval = 30
    path = "/graph"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
  }
}

#Creating target group attachment workernode
resource "aws_lb_target_group_attachment" "grafana-tg-att" {
  target_group_arn = aws_lb_target_group.grafana-tg.arn
  target_id = element(split(",", join(",", "${var.instance}")),count.index)
  port = 31300
  count = 3
}

#Creating load balancer listener for http
resource "aws_lb_listener" "grafana-http" {
  load_balancer_arn = aws_lb.grafana-lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    # type = "forward"
    # target_group_arn = aws_lb_target_group.grafana-tg.arn
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTPS_301"
    }
  }
}

#Creating load balancer listener for https
resource "aws_lb_listener" "grafana-https" {
  load_balancer_arn = aws_lb.grafana-lb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.grafana-tg.arn
  }
}


#Creating prod lb
resource "aws_lb" "prom-lb" {
  name = var.prom-lb-tag
  internal = false
  load_balancer_type = "application"
  security_groups = var.kube-sg
  subnets = var.kube-subnet
  enable_deletion_protection = false
  tags = {
    Name = var.prom-lb-tag
  }
}

#Creating prod target group
resource "aws_lb_target_group" "prom-tg" {
  name = var.prom-tg-tag
  port = 31090
  protocol = "HTTP"
  vpc_id = var.vpc-id

  health_check {
    interval = 30
    path = "/graph"
    timeout = 5
    healthy_threshold = 3
    unhealthy_threshold = 5
  }
}

#Creating target group attachment workernode
resource "aws_lb_target_group_attachment" "prom-tg-att" {
  target_group_arn = aws_lb_target_group.prom-tg.arn
  target_id = element(split(",", join(",", "${var.instance}")),count.index)
  port = 31090
  count = 3
}

#Creating load balancer listener for http
resource "aws_lb_listener" "prom-http" {
  load_balancer_arn = aws_lb.prom-lb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    # type = "forward"
    # target_group_arn = aws_lb_target_group.prom-tg.arn
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTPS_301"
    }
  }
}

#Creating load balancer listener for https
resource "aws_lb_listener" "prom-https" {
  load_balancer_arn = aws_lb.prom-lb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.prom-tg.arn
  }
}
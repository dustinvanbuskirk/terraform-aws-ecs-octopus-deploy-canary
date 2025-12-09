# Security Groups for Application Load Balancers
resource "aws_security_group" "alb" {
  for_each = length(var.alb_security_group_ids) == 0 ? local.environments : {}

  name        = "${each.value.alb_name}-sg"
  description = "Security group for ${local.service_name} ALB - ${each.value.name}"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${each.value.alb_name}-sg"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# Application Load Balancers
resource "aws_lb" "main" {
  for_each = local.environments

  name               = each.value.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = length(var.alb_security_group_ids) > 0 ? var.alb_security_group_ids : [aws_security_group.alb[each.key].id]
  subnets            = var.alb_subnet_ids

  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  idle_timeout                     = var.idle_timeout

  tags = {
    Name        = each.value.alb_name
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
    Purpose     = "ECS Canary Deployments"
  }
}

# Blue Target Groups
resource "aws_lb_target_group" "blue" {
  for_each = local.environments

  name        = "${local.service_name}-blue-${each.key}"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 2
    interval            = 5
    path                = "/"
    port                = "4000"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name        = "${local.service_name}-blue-${each.key}"
    Stack       = "Blue"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# Green Target Groups
resource "aws_lb_target_group" "green" {
  for_each = local.environments

  name        = "${local.service_name}-green-${each.key}"
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 2
    interval            = 5
    path                = "/"
    port                = "4000"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name        = "${local.service_name}-green-${each.key}"
    Stack       = "Green"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# Load Balancer Listeners
resource "aws_lb_listener" "main" {
  for_each = local.environments

  load_balancer_arn = aws_lb.main[each.key].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }

  tags = {
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# Load Balancer Listener Rules - Traffic Splitting
resource "aws_lb_listener_rule" "traffic_split" {
  for_each = local.environments

  listener_arn = aws_lb_listener.main[each.key].arn
  priority     = 10

  action {
    type = "forward"

    forward {
      target_group {
        arn    = aws_lb_target_group.blue[each.key].arn
        weight = 100
      }

      target_group {
        arn    = aws_lb_target_group.green[each.key].arn
        weight = 0
      }

      stickiness {
        enabled  = false
        duration = 600
      }
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = {
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      action[0].forward[0].target_group
    ]
  }
}

# Testing Rules - Direct traffic to green with query string
resource "aws_lb_listener_rule" "green_testing" {
  for_each = local.environments

  listener_arn = aws_lb_listener.main[each.key].arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green[each.key].arn
  }

  condition {
    query_string {
      value = "test=true"
    }
  }

  tags = {
    Purpose     = "Testing"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}
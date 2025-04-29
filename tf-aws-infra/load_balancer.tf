# Target Group for the Application Load Balancer
resource "aws_lb_target_group" "webapp_tg" {
  # Name of the target group (must be unique per region/VPC)
  name = "webapp-tg"
  port = var.application_port

  # Protocol used for routing traffic to targets
  protocol = "HTTP"

  # VPC in which the target group is created
  vpc_id = aws_vpc.main.id

  # Health check configuration for ALB to determine instance health
  health_check {
    # The path the ALB will use to perform health checks
    path = "/healthz"

    # Time between health checks (in seconds)
    interval = 30

    # Time ALB will wait for a response before marking it as failed
    timeout = 10

    # Number of consecutive successful checks before marking instance as healthy
    healthy_threshold = 3

    # Number of consecutive failed checks before marking instance as unhealthy
    unhealthy_threshold = 3

    # ALB expects a response code in this range to consider it healthy
    matcher = "200-299"
  }

  lifecycle {
    create_before_destroy = false
  }

  tags = {
    Name = "webapp-tg"
  }
}

# Application Load Balancer
resource "aws_lb" "webapp_alb" {
  name_prefix        = "applb-"
  internal           = false # public-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer_sg.id]
  subnets            = aws_subnet.public_subnets[*].id # ALB must be in public subnets

  lifecycle {
    create_before_destroy = false
  }

  tags = {
    Name = "webapp-alb"
  }
}

# Create ACM certificate only in DEV environment
resource "aws_acm_certificate" "dev_cert" {
  count             = var.environment == "DEV" ? 1 : 0
  domain_name       = var.subdomain_name
  validation_method = "DNS"

  tags = {
    Environment = var.environment
  }
}

# Create DNS validation records only in DEV
resource "aws_route53_record" "dev_cert_validation" {
  for_each = var.environment == "DEV" ? {
    for dvo in aws_acm_certificate.dev_cert[0].domain_validation_options : dvo.domain_name => dvo
  } : {}

  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  zone_id = data.aws_route53_zone.subdomain_zone.zone_id
  records = [each.value.resource_record_value]
  ttl     = 60
}

# Validate certificate
resource "aws_acm_certificate_validation" "dev_cert_validation" {
  count = var.environment == "DEV" ? 1 : 0

  certificate_arn         = aws_acm_certificate.dev_cert[0].arn
  validation_record_fqdns = [for r in aws_route53_record.dev_cert_validation : r.fqdn]
}

# Data source for existing demo cert
data "aws_acm_certificate" "demo_cert" {
  count       = var.environment == "DEMO" ? 1 : 0
  domain      = var.subdomain_name
  statuses    = ["ISSUED"]
  most_recent = true
}


# Look for issued certificates in the domain 
# data "aws_acm_certificate" "selected" {
#   domain      = var.subdomain_name
#   statuses    = ["ISSUED"]
#   most_recent = true
# }

# Listener for HTTP traffic
resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapp_alb.arn
  # port              = 80
  # protocol          = "HTTP"
  port     = 443
  protocol = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = var.environment == "DEV" ? aws_acm_certificate_validation.dev_cert_validation[0].certificate_arn : data.aws_acm_certificate.demo_cert[0].arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp_tg.arn
  }

  depends_on = [
    aws_lb.webapp_alb,
    aws_lb_target_group.webapp_tg
  ]
}

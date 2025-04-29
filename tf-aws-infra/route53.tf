# Look up the hosted zone for the subdomain
data "aws_route53_zone" "subdomain_zone" {
  # Add a trailing dot because Route53 typically stores zone names this way
  name         = "${var.subdomain_name}."
  private_zone = false
}

# Create an alias A record pointing to the ALB
resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.subdomain_zone.zone_id
  name    = var.subdomain_name
  type    = "A"

  alias {
    name                   = aws_lb.webapp_alb.dns_name
    zone_id                = aws_lb.webapp_alb.zone_id
    evaluate_target_health = true
  }

  # ttl = 60
}

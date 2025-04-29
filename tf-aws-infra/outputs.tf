# output "ec2_public_ip" {
#   description = "Public IP of the deployed EC2 instance"
#   value       = aws_instance.webapp_instance.public_ip
# }

# output "webapp_url" {
#   description = "URL to access the web application"
#   value       = "http://${var.subdomain_name}/"
# }

# Issued ssl certificate for production domain - DEMO
output "webapp_url" {
  description = "URL to access the web application"
  value       = "https://${var.subdomain_name}/"
}
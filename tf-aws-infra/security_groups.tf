# Security Group for EC2 instance (Application Security Group)
resource "aws_security_group" "application_security_group" {
  name = "csye6225_app_sg"
  # description = "Allow SSH, HTTP, HTTPS, and application traffic"
  description = "Allow traffic only from the Load Balancer SG"
  vpc_id      = aws_vpc.main.id # Access the newly created VPC

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # security_groups = [aws_security_group.load_balancer_sg.id]
  }

  # Assignment7 - no access to the public internet, 
  # Source of the traffic should be the load balancer security group

  # HTTP access
  # ingress {
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # # HTTPS access
  # ingress {
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Allow application traffic (port 3000)
  ingress {
    from_port = var.application_port
    to_port   = var.application_port
    protocol  = "tcp"
    # cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  # Allow outbound traffic to RDS on PostgreSQL port (5432) 
  # (Redundant code with below which already allows all outbound traffic)
  # egress {
  #   from_port   = var.rds_port
  #   to_port     = var.rds_port
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application_security_group"
  }
}

# Security Group for RDS instance (Database Security Group)
resource "aws_security_group" "database_security_group" {
  name        = "csye6225_database_sg"
  description = "Allow PostgreSQL traffic from application EC2 instance"
  vpc_id      = aws_vpc.main.id

  # Allow inbound PostgreSQL traffic (port 5432) ONLY from EC2 Security Group
  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [aws_security_group.application_security_group.id] # Only allow from EC2 SG
  }

  # Allow outbound traffic (for database updates & external connectivity)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database_security_group"
  }
}

# Security Group for Load Balancer (Application Load Balancer Security Group)

resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg"
  description = "Security group for Application Load Balancer - allows HTTP and HTTPS"
  vpc_id      = aws_vpc.main.id # Replace with your actual VPC resource name

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load_balancer_security_group"
  }
}

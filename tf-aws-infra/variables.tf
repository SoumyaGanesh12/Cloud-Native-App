# Stores all input variables

variable "aws_profile" {
  description = "AWS CLI Profile - Dev/ Demo profiles"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "Main-VPC"
}

variable "subnet_mask" {
  description = "Number of additional bits to add for subnetting"
  type        = number
  default     = 8 # Default to /24 subnets
}

variable "num_public_subnets" {
  description = "Number of public subnets to create"
  type        = number
}

variable "num_private_subnets" {
  description = "Number of private subnets to create"
  type        = number
}

variable "internet_gateway_name" {
  description = "Name for the Internet Gateway"
  type        = string
  default     = "Main-IGW"
}

variable "subnet_prefix" {
  description = "Unique identification for subnet"
  type        = string
}

variable "ami_id" {
  description = "The AMI ID created by Packer"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"
}

variable "application_port" {
  description = "Port on which the web application runs"
  type        = number
  default     = 3000
}

// RDS instance variables
variable "rds_port" {
  description = "Port for PostgreSQL"
  default     = 5432
}

variable "db_engine" {
  description = "Database engine type"
  default     = "postgres"
}

variable "db_engine_version" {
  description = "PostgreSQL version"
  default     = "16"
}

variable "db_parameter_group_name" {
  description = "Name of the RDS parameter group"
  default     = "csye6225-postgres-param-group"
}

variable "db_instance_class" {
  description = "RDS instance class (cheapest one)"
  default     = "db.t3.micro"
}

variable "db_identifier" {
  description = "Database instance identifier"
  default     = "csye6225"
}

variable "db_username" {
  description = "Master username for the RDS database"
  default     = "csye6225"
}

variable "db_password" {
  description = "Master password for the RDS database"
  sensitive   = true # Ensures Terraform does not log it in plaintext
}

variable "db_name" {
  description = "Database name"
  default     = "csye6225"
}

variable "test_db_name" {
  description = "Test database name"
  default     = "csye6225"
}

variable "db_dialect" {
  description = "Database dialect"
  default     = "postgres"
}


variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "publicly_accessible" {
  description = "Public accessibility of RDS"
  default     = false
}

# Subdomain for dev and demo
variable "subdomain_name" {
  type        = string
  description = "The subdomain name (without trailing dot), e.g. dev.example.me or demo.example.me"
}

variable "key_name" {
  description = "Name of the EC2 Key Pair for SSH access"
  type        = string
}

variable "asg_min_size" {
  description = "Minimum number of EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of EC2 instances in ASG"
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Initial desired number of EC2 instances in ASG"
  type        = number
  default     = 1
}

variable "scale_up_threshold" {
  description = "CPU % threshold to trigger scale-up"
  type        = number
  default     = 10
}

variable "scale_down_threshold" {
  description = "CPU % threshold to trigger scale-down"
  type        = number
  default     = 8
}

# AWS Key management

variable "aws_account_id" {
  description = "The AWS account ID for KMS and IAM policies"
  type        = string
  default     = 443370686847 # dev account
}

variable "db_password_length" {
  description = "Length of the randomly generated DB password"
  type        = number
  default     = 16
}

variable "db_password_special" {
  description = "Whether to include special characters in the DB password"
  type        = bool
  default     = true
}

variable "db_password_override_special" {
  description = "Allowed special characters in the DB password (avoiding /, @, \" and space)"
  type        = string
  default     = "!#$%^&*()-_=+[]{}<>:?"
}

variable "environment" {
  description = "Deployment environment (DEV or DEMO)"
  type        = string
}
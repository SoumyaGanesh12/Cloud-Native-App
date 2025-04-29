# Define plugins
packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0, < 2.0.0"
      source  = "github.com/hashicorp/amazon"
    }
    # googlecompute = {
    #   version = ">= 1.0.0, < 2.0.0"
    #   source  = "github.com/hashicorp/googlecompute"
    # }
  }
}

# Define input variables

# AWS Related Variables
variable "aws_region" {
  type        = string
  description = "AWS region where the AMI will be built"
  default     = "us-east-1"
}

# variable "ami_regions" {
#   type        = list(string)
#   description = "List of AWS regions where the AMI will be copied after creation"
#   default = [
#     "us-west-1",
#   ]
# }

variable "instance_type" {
  type        = string
  description = "EC2 instance type used during the image build"
  default     = "t2.small"
}

variable "demo_account_id" {
  type        = string
  description = "AWS demo account ID"
  default     = "123"
}

# GCP Related Variables
# variable "gcp_project_id" {
#   type        = string
#   description = "GCP Project ID"
#   default     = "sample-projectid"
# }

# variable "gcp_region" {
#   type        = string
#   description = "GCP region where the image will be built"
#   default     = "us-central1"
# }

# variable "gcp_zone" {
#   type        = string
#   description = "GCP zone where the image will be built"
#   default     = "us-central1-a"
# }

# variable "machine_type" {
#   type        = string
#   description = "GCP machine type used for building the image"
#   default     = "e2-medium"
# }

variable "ssh_username" {
  type        = string
  description = "SSH username"
  default     = "ubuntu"
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID where the AMI build instance will be launched"
  default     = "subnet-063c1a44960f2048a"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the AMI build instance will be launched"
  default     = "vpc-063489db1d8f45a74"
}

variable "port" {
  type        = number
  default     = 8080
  description = "The port number for the application"
}

# Database-related variables
variable "db_name" {
  type        = string
  description = "Primary database name for the application"
  default     = "application_db"
}

variable "test_db_name" {
  type        = string
  description = "Test database name used for CI/CD testing"
  default     = "test_db"
}

variable "db_user" {
  type        = string
  description = "Database username"
  default     = "db_username"
}

variable "db_pass" {
  type        = string
  description = "Database password"
  default     = "db_password"
}

variable "db_dialect" {
  type        = string
  description = "The dialect for the database"
  default     = "postgres"
}

variable "db_host" {
  type        = string
  description = "The host where the database is located"
  default     = "localhost"
}

# AWS Source
source "amazon-ebs" "ubuntu" {
  ami_name                    = "CSYE6225_WEBAPP_${formatdate("YYYY-MM-DD_hh-mm-ss", timestamp())}"
  ami_description             = "AMI for CSYE 6225 Web Application"
  instance_type               = var.instance_type
  region                      = var.aws_region
  ssh_username                = var.ssh_username
  subnet_id                   = var.subnet_id
  vpc_id                      = var.vpc_id
  associate_public_ip_address = true
  ami_virtualization_type     = "hvm"
  ami_users                   = [var.demo_account_id]

  source_ami_filter {
    filters = {
      name                = "ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical's AWS account ID
  }

  # ami_regions = var.ami_regions

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/sda1"
    volume_size           = 25
    volume_type           = "gp2"
  }

}

# GCP Source
# source "googlecompute" "gcp_image" {
#   project_id   = var.gcp_project_id
#   region       = var.gcp_region
#   zone         = var.gcp_zone
#   machine_type = var.machine_type
#   image_name   = "csye6225-webapp-${formatdate("YYYYMMDD-HHmmss", timestamp())}"
#   source_image = "ubuntu-2404-noble-amd64-v20250214"
#   disk_size    = 25
#   ssh_username = var.ssh_username
# }

build {
  name        = "csye6225_webapp_image"
  description = "Builds an AMI for the CSYE 6225 Web Application with all dependencies pre-installed"
  sources = [
    "source.amazon-ebs.ubuntu",
    # "source.googlecompute.gcp_image",
  ]

  # Copy provisioning script
  provisioner "file" {
    # Assignment 5 - uses rds instance
    source      = "setup.sh"
    destination = "/tmp/setup.sh"
    # Assignment 4 - uses webapp-setup script with db installations
    # source      = "webapp-setup.sh"
    # destination = "/tmp/webapp-setup.sh"
  }

  # Provision CloudWatch Agent configuration file
  provisioner "file" {
    source      = "amazon-cloudwatch-agent.json"
    destination = "/tmp/amazon-cloudwatch-agent.json"
  }

  # Provision CloudWatch Agent installation script
  provisioner "file" {
    source      = "cloudwatch-agent.sh"
    destination = "/tmp/cloudwatch-agent.sh"
  }

  # Copy the web application ZIP file
  provisioner "file" {
    source      = "webapp.zip"
    destination = "/tmp/webapp.zip"
  }

  # Copy systemd service file
  provisioner "file" {
    source      = "webapp.service"
    destination = "/tmp/webapp.service"
  }

  # Run the provisioning script with environment variables
  provisioner "shell" {
    environment_vars = [
      "AWS_REGION=${var.aws_region}",
      # "GCP_PROJECT_ID=${var.gcp_project_id}",
      # "GCP_ZONE=${var.gcp_zone}",
      # "GCP_REGION=${var.gcp_region}",
      "PORT=${var.port}",
      "DB_DIALECT=${var.db_dialect}",
      # Assignment 4 - required db credentials
      # "DB_NAME=${var.db_name}",
      # "TEST_DB_NAME=${var.test_db_name}",
      # "DB_USER=${var.db_user}",
      # "DB_PASS=${var.db_pass}",
      # "DB_HOST=${var.db_host}",
      # "DB_DIALECT=${var.db_dialect}",
    ]
    inline = [
      # Assignment 5 script - use rds instance instead of locally installing db
      "chmod +x /tmp/setup.sh",
      "sudo -E /tmp/setup.sh"
      # Assignment 4 script
      # "chmod +x /tmp/webapp-setup.sh",
      # "sudo -E /tmp/webapp-setup.sh"
    ]
  }

  # Execute the CloudWatch Agent installation script after initial setup
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/cloudwatch-agent.sh",
      "sudo /tmp/cloudwatch-agent.sh"
    ]
  }

}


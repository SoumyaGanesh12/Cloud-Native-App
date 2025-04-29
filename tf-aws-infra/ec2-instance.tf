# resource "aws_instance" "webapp_instance" {
#   ami                         = var.ami_id
#   instance_type               = var.instance_type
#   subnet_id                   = aws_subnet.public_subnets[0].id # EC2 in public subnet
#   vpc_security_group_ids      = [aws_security_group.application_security_group.id]
#   associate_public_ip_address = true                                               # Ensures SSH access
#   disable_api_termination     = false                                              # Termination protection disabled
#   iam_instance_profile        = aws_iam_instance_profile.ec2_instance_profile.name # Attach IAM Role

#   # Pass Database Credentials to EC2 via User Data
#   user_data = <<-EOF
#     #!/bin/bash

#     echo "DB_HOST=$(echo ${aws_db_instance.database_instance.endpoint} | cut -d ':' -f1)" >> /opt/csye6225/webapp/.env
#     echo "DB_USER=${var.db_username}" >> /opt/csye6225/webapp/.env
#     echo "DB_PASS=${var.db_password}" >> /opt/csye6225/webapp/.env
#     echo "DB_NAME=${var.db_name}" >> /opt/csye6225/webapp/.env
#     echo "DB_DIALECT=${var.db_dialect}" >> /opt/csye6225/webapp/.env
#     echo "DB_PORT=${var.rds_port}" >> /opt/csye6225/webapp/.env
#     echo "TEST_DB_NAME=${var.test_db_name}" >> /opt/csye6225/webapp/.env
#     echo "AWS_REGION=${var.aws_region}" >> /opt/csye6225/webapp/.env
#     echo "S3_BUCKET=${aws_s3_bucket.webapp_bucket.id}" >> /opt/csye6225/webapp/.env
#     echo "PORT=${var.application_port}" >> /opt/csye6225/webapp/.env

#     # Configure and restart the CloudWatch Agent using the local configuration file
#     sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#       -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

#     # Restart the CloudWatch Agent service to ensure it is running with the latest config
#     sudo systemctl enable amazon-cloudwatch-agent
#     sudo systemctl restart amazon-cloudwatch-agent

#     echo "CloudWatch Agent has been configured and restarted."

#     # Restart application to use new credentials
#     sudo systemctl daemon-reload
#     sudo systemctl enable webapp.service
#     sudo systemctl restart webapp.service  

#     echo "Checking status of the webapp service..."
#     sudo systemctl status webapp.service --no-pager
#   EOF

#   root_block_device {
#     volume_size           = 25
#     volume_type           = "gp2"
#     delete_on_termination = true
#   }

#   tags = {
#     Name = "CSYE6225-webapp-instance"
#   }
# }

// Launch ec2 instances through launch templates
resource "aws_launch_template" "webapp_lt" {
  name_prefix   = "csye6225-asg-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name # Add this if you were using a key

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    
    # Install dependencies
    sudo apt update && sudo apt install -y unzip jq curl

    # Install AWS CLI v2
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Fetch DB password from Secrets Manager (dynamic name)
    SECRET_NAME="${aws_secretsmanager_secret.db_password.name}"
    DB_PASS=$(aws secretsmanager get-secret-value \
      --region ${var.aws_region} \
      --secret-id "$SECRET_NAME" \
      --query 'SecretString' \
      --output text | jq -r .password)

    echo "DB_HOST=$(echo ${aws_db_instance.database_instance.endpoint} | cut -d ':' -f1)" >> /opt/csye6225/webapp/.env
    echo "DB_USER=${var.db_username}" >> /opt/csye6225/webapp/.env
    # echo "DB_PASS=${var.db_password}" >> /opt/csye6225/webapp/.env
    echo "DB_PASS=$DB_PASS" >> /opt/csye6225/webapp/.env
    echo "DB_NAME=${var.db_name}" >> /opt/csye6225/webapp/.env
    echo "DB_DIALECT=${var.db_dialect}" >> /opt/csye6225/webapp/.env
    echo "DB_PORT=${var.rds_port}" >> /opt/csye6225/webapp/.env
    echo "TEST_DB_NAME=${var.test_db_name}" >> /opt/csye6225/webapp/.env
    echo "AWS_REGION=${var.aws_region}" >> /opt/csye6225/webapp/.env
    echo "S3_BUCKET=${aws_s3_bucket.webapp_bucket.id}" >> /opt/csye6225/webapp/.env
    echo "PORT=${var.application_port}" >> /opt/csye6225/webapp/.env

    # Configure and restart the CloudWatch Agent using the local configuration file
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

    # Restart the CloudWatch Agent service to ensure it is running with the latest config
    sudo systemctl enable amazon-cloudwatch-agent
    sudo systemctl restart amazon-cloudwatch-agent

    echo "CloudWatch Agent has been configured and restarted."
   
    # Restart application to use new credentials
    sudo systemctl daemon-reload
    sudo systemctl enable webapp.service
    sudo systemctl restart webapp.service  

    echo "Checking status of the webapp service..."
    sudo systemctl status webapp.service --no-pager
  EOF
  )

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application_security_group.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 25
      volume_type           = "gp2"
      delete_on_termination = true
      # Add KMS keys for EC2(EBS) encryption
      encrypted  = true
      kms_key_id = aws_kms_key.ec2_key.arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "asg-webapp-instance"
    }
  }
}

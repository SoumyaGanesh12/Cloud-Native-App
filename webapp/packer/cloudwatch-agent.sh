#!/bin/bash
# install-cloudwatch-agent.sh
# This script installs and configures the Unified CloudWatch Agent on Ubuntu,
# and adjusts the log directory permissions so that the custom user (csye6225) can access the logs.
set -e
set -x
export DEBIAN_FRONTEND=noninteractive

# Download the latest CloudWatch Agent package for Ubuntu
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb -O /tmp/amazon-cloudwatch-agent.deb

# Install the CloudWatch Agent package
sudo dpkg -i /tmp/amazon-cloudwatch-agent.deb

# Create the CloudWatch Agent configuration directory if it doesn't exist
sudo mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

# Copy the CloudWatch Agent configuration file (provisioned to /tmp)
sudo cp /tmp/amazon-cloudwatch-agent.json /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Create the application log directory (if not already present) and set permissions so that the custom user can access it
sudo mkdir -p /opt/csye6225/webapp/logs
sudo chown -R csye6225:csye6225 /opt/csye6225/webapp/logs
sudo chmod -R 755 /opt/csye6225/webapp/logs

# Start the CloudWatch Agent using the provided configuration file
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Enable the CloudWatch Agent service to start automatically at boot
sudo systemctl enable amazon-cloudwatch-agent.service

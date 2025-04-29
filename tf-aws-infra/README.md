## Assignment 3

# 🚀 AWS Networking Infrastructure with Terraform

## Overview
This repository provisions AWS networking resources using **Terraform** for automated infrastructure management. The setup includes **Virtual Private Cloud (VPC), Subnets, Internet Gateway, Route Tables, and Routes**, following Infrastructure-as-Code (IaC) best practices.

## Features
- **Creates a Virtual Private Cloud (VPC)**
- **Provisioning Public and Private Subnets**
- **Configuring an Internet Gateway and Route Tables**
- **Public Route Table with Internet Access**
- **Private Route Table for Internal Communication**
- **Multiple Environment Support (`dev`, `demo`)**
- **Implements Branch Protection & Continuous Integration (CI) with GitHub Actions**

## Setting Up AWS CLI & Terraform

### **1. Install AWS CLI**
Follow [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).

### **2️. Configure AWS CLI Profiles**
Create AWS CLI profiles for different environments:
```sh
aws configure --profile (profilename)
```

### **3️. Install Terraform**
Download and install Terraform from the Terraform Official Website.

Verify installation:
```sh
terraform -version
```

## Infrastructure as Code with Terraform

### Steps to Set Up Infrastructure
1. Clone this repository:
   ```sh
   git clone repository-url
   cd path
   ```
   Provide proper values for variables to setup the infrastructure.
2. Initialize Terraform:
   ```sh
   terraform init
   ```
3. Plan the infrastructure changes:
   ```sh
   terraform plan
   ```
4. Apply the changes to provision resources:
   ```sh
   terraform apply
   ```
5. To destroy resources when no longer needed:
   ```sh
   terraform destroy
   ```

## Continuous Integration (CI)

### CI for Terraform
- A GitHub Actions workflow will be triggered on every pull request to:
  - Execute `terraform fmt` and `terraform validate` to ensure code consistency and correctness.
  - Restrict merging if any validation checks fail.

## Assignment 4

# 🚀 Launch AWS EC2 instance with Terraform

### 1. **Application Security Group**
- A security group for EC2 instances hosting the web application.
- Ingress rules allow traffic on:
  - **Port 22** (SSH)
  - **Port 80** (HTTP)
  - **Port 443** (HTTPS)
  - **Application Port** (Specify the port your application runs on)
- Traffic is allowed from anywhere (`0.0.0.0/0`).

### 2. **EC2 Instance**
- **AMI**: Custom AMI (defined in the Terraform configuration)
- **Security Group**: The application security group is attached.
- The instance is launched inside the **Terraform-created VPC**, **not** the default AWS VPC.

## Notes -
- Ensure that your AWS credentials are properly set (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).
- Modify the Terraform variables as needed before applying.

## Assignment 5

# 🚀 AWS Resources & Architecture

### 1. **Amazon S3 (Simple Storage Service)**
- **Purpose**: Stores uploaded files and serves as a storage backend.
- **Access Control**: 
  - **IAM Policies** restrict access to the bucket.
  - Only the web application (running on EC2) can read/write.
  - Public access is **disabled**.
- **Lifecycle Rules**: 
  - Older files can be archived using **S3 lifecycle policies**.

### 2. **Amazon EC2 (Elastic Compute Cloud)**
- **Purpose**: Hosts the web application.
- **AMI (Amazon Machine Image)**:
  - Uses a **custom AMI** (built with **Packer**).
  - Includes required software and dependencies for the web application.
- **User Data Script**: 
  - Executes **during instance launch** to configure the environment.
  - Installs dependencies, sets up the application, and starts the service.
  - Example:
    ```sh
    #!/bin/bash
    yum update -y
    yum install -y nodejs
    cd /home/ec2-user/app
    npm install
    npm start
    ```

### 3. **Amazon RDS (PostgreSQL)**
- **Purpose**: Serves as the database for the application.
- **Parameter Group**:
  - A **custom parameter group** is defined to optimize database performance.
- **Subnet Group**:
  - Defines which **private subnets** the RDS instance can reside in.
  - Ensures the database is **not exposed to the public internet**.
- **Security**:
  - **IAM authentication** is enabled for **secure access**.
  - Only the **EC2 instances** (within the VPC) can access the database.

### 4. **Security Groups & Network Configuration**
#### **VPC (Virtual Private Cloud)**
- A dedicated **VPC** is created for the application, providing **network isolation**.
- **Private Subnets** are configured for EC2 and RDS.

#### **Security Groups**
| Security Group | Inbound Rules | Outbound Rules | Purpose |
|---------------|--------------|---------------|---------|
| **Web SG** (for EC2) | Allow **HTTP (80), HTTPS (443), SSH (22) only from trusted IPs** | All traffic allowed | Secures the application server |
| **RDS SG** (for DB) | Allow **PostgreSQL (5432) only from EC2 instances** | Deny public access | Restricts database access |

### 5. **IAM Roles & Policies**
- **IAM Role for EC2**:
  - Grants **S3 access** for reading/writing files.
- **IAM Policy for S3**:
  - Limits access to specific **buckets and prefixes**.
  - Example policy:
    ```json
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": ["arn:aws:s3:::my-app-bucket/*"]
    }
    ```
- **IAM Role for RDS**:
  - Allows EC2 instances to use **IAM-based database authentication**.

## 🔗 Interrelationships Between Components
| **Component** | **Interacts With** | **Purpose** |
|--------------|------------------|-------------|
| **EC2 Instance** | S3 | Stores and retrieves files |
| **EC2 Instance** | RDS | Connects to the database |
| **Security Groups** | EC2, RDS | Restricts network access |
| **IAM Roles** | EC2, RDS, S3 | Grants required permissions |

This Terraform configuration ensures a secure, scalable, and highly available infrastructure for the web application by leveraging AWS services, enforcing strict access controls, automating instance provisioning, and optimizing network security and database performance, resulting in a robust and efficient cloud deployment. 

## Assignment 6

# 🚀 Logs & Metrics - AWS CLoudWatch Agent

This Terraform configuration manages IAM roles, and EC2 instance settings to support our web application integrated with AWS CloudWatch for logging and custom metrics. It attaches a unified IAM role (combining custom S3/RDS access with the AWS managed CloudWatchAgentServerPolicy) to the EC2 instance, and provisions an instance that automatically starts the CloudWatch Agent.

## Key Components

- **IAM Roles & Policies:**  
  - A unified IAM role combines custom permissions (for S3 and RDS access) with the AWS managed CloudWatchAgentServerPolicy.
  - The role is attached to the EC2 instance via an instance profile, ensuring the instance has the required permissions to send logs and metrics to CloudWatch.

- **EC2 Instance Provisioning:**  
  - The EC2 instance is launched using an AMI built with Packer.
  - The instance's user data script configures environment variables, restarts the web application service, and starts the CloudWatch Agent for real‑time logging and metric collection.

- **Monitoring & Logging:**  
  - The application uses Winston to generate logs at appropriate levels (INFO, ERROR, etc.) which are written to a designated file.
  - Custom metrics (such as API call counts and timer metrics) are collected using node‑statsd and forwarded to CloudWatch via the CloudWatch Agent.

## Validation

After deployment, validate the following:

- **Logs:**  
  - **On the Instance:**  
    SSH into your EC2 instance and confirm that the log file exists and is being updated:
    ```bash
    ls -l /opt/csye6225/webapp/logs/webapp.log
    tail -n 50 /opt/csye6225/webapp/logs/webapp.log
    ```
  - **In CloudWatch Logs:**  
    Verify in the AWS CloudWatch console that the log group (e.g., `csye6225-webapp`) contains log streams with the expected log events.

- **Metrics:**  
  In the AWS CloudWatch Metrics console, locate your custom metrics (e.g., `api.file.upload.count` and `api.file.upload.duration`) under the appropriate namespace (e.g., `CWAgent`). Confirm that the data points reflect the correct aggregated values over the configured intervals.

## Assignment 7

# 🚀 Auto Scaling, Load Balancer, and DNS Integration

This assignment extends the infrastructure to support dynamic scaling and a stable domain endpoint using an Application Load Balancer (ALB), Auto Scaling Group (ASG), and Amazon Route 53 DNS configuration.

## Infrastructure Features

### Application Load Balancer (ALB)
- Configured to listen on port 80 for HTTP traffic.
- Forwards requests to registered EC2 instances via a target group.
- Health checks configured on `/healthz`.

### Route53 DNS Setup
- Domain purchased from Namecheap and delegated to AWS Route 53.
- Public hosted zones created for root, `dev`, and `demo` environments.
- Subdomain A-records (e.g., `dev.yourdomain.me`) created as ALIAS pointing to the ALB.

### Auto Scaling Group (ASG)
- Launches EC2 instances from a defined Launch Template.
- Minimum size: 1, Maximum size: 5, Desired capacity: 1. (All these values are configurable)
- Instances registered with the ALB target group.

### Launch Template
- Uses custom AMI with pre-installed application and systemd service.
- Includes IAM role, security group, block device mapping, and user data script.

### EC2 Health Checks
- ASG uses EC2-level health checks for scaling decisions.
- ALB uses HTTP health checks (`/healthz`) to maintain traffic only to healthy instances.

### CloudWatch Alarms & Scaling Policies
- CPU > 5%: triggers scale-up policy (add 1 instance).
- CPU < 3%: triggers scale-down policy (remove 1 instance).
- CloudWatch alarms monitor CPU utilization of the ASG.

### Security Groups
- Load Balancer SG: allows HTTP (80) and HTTPS (443) from anywhere.
- Application SG: allows traffic only from the Load Balancer SG.
- Direct SSH or HTTP access to EC2 from the public internet is blocked.

### Logging & Monitoring
- Winston used for structured web application logging (`info`, `warn`, `debug`, `error`).
- StatsD metrics integrated for API usage and performance timing.
- Logs available via CloudWatch if CloudWatch Agent is installed in AMI.

## Assignment 7

# 🚀 Infrastructure Security and Encryption

This assignment implements infrastructure security using **AWS KMS**, **Secrets Manager**, and **SSL Certificates** in accordance with best practices.

## AWS Key Management Service (KMS)

Separate **KMS keys** are created and used for:

- **EC2** volume encryption (via Launch Template)
- **RDS** storage encryption
- **S3 Buckets** (used for storing uploaded files)
- **Secrets Manager** (for storing DB password securely)

### Key Rotation
- All KMS keys have **automatic rotation enabled** (90-day period).

## Database Password Management

- The **RDS DB password** is generated using `random_password` in Terraform.
- This password is stored in **AWS Secrets Manager**, encrypted with a **custom KMS key**.
- A random suffix is added to the secret name for uniqueness.
- The password is retrieved in the **EC2 user data script** at launch time and injected into `.env`.

## Secrets Manager Access from EC2

The EC2 instance role is granted permissions via IAM policy to:

- Access the database password in **Secrets Manager**
- Decrypt the secret using the **custom KMS key**
- Run startup logic via user data

## SSL Certificates for ALB

### DEV Environment
- Can use **AWS Certificate Manager (ACM)** to request a **free SSL certificate**.
- Certificate is automatically validated via **Route53 DNS records**.
- HTTPS listener on ALB uses this certificate.

### DEMO Environment
- Uses a **manually imported certificate** purchased from Namecheap.
- Certificate must be imported into **ACM in the DEMO account** before deployment.
- ALB’s HTTPS listener uses this imported certificate.

### Import Certificate Command

This is the command used to import the certificate into ACM for the DEMO environment:

```bash
aws acm import-certificate \
  --certificate fileb://demo_soumyaganesh_me.crt \
  --private-key fileb://private.key \
  --certificate-chain fileb://demo_soumyaganesh_me.crt \
  --region us-east-1 \
  --profile demo

## Assignment 1

## 🚀 Overview

This is a simple Node.js-based web application that uses Express, Sequelize, and PostgreSQL to provide a `/healthz` endpoint for monitoring the health of the application and its database connection. It adheres to RESTful principles and is designed to handle basic health checks by:

- Verifying the database connection.
- Logging insightful records in a PostgreSQL database.

## Features

### Database Bootstrapping

- Automatically creates tables on startup if they don’t exist.
- Uses Sequelize ORM for database interactions.

### RESTful API

- **/healthz endpoint:**
  - Verifies database connectivity.
  - Inserts a health check record with a timestamp.
  - Returns appropriate HTTP status codes:
    - `200` for success.
    - `503` for database connectivity issues.
    - `400` for bad requests.
    - `405` for unsupported methods.

### Error Handling

- Graceful error handling for database connectivity issues and unsupported requests.

### Error Handling

- Graceful error handling for database connectivity issues and unsupported requests.

### Automated Testing

- Uses **Jest** as the testing framework.
- Includes unit tests and integration tests for API endpoints.

### Scalable Architecture

- **Modular code structure:**
  - **models** for database schema.
  - **services** for business logic.
  - **controllers** for handling requests.
  - **routes** for API routing.
  
## Prerequisites

### Install Required Software
- **Node.js** (v16+)
- **PostgreSQL** (v13+)
- **Git** (optional)

### Set Up PostgreSQL Database
1. Create a PostgreSQL database.
2. Note the following details:
   - Database name
   - Test Database name
   - Username
   - Password
   - Host
   - Port

## API Documentation

### Endpoint: `/healthz`
- **Description:** Monitors the health of the application and database.
- **HTTP Method:** `GET`

#### Request:
- No payload allowed.
- `Content-Length` must be `0`.

#### Response:
- **200 OK:** Database is healthy, and a health check record was created.
- **503 Service Unavailable:** Database is unreachable.
- **400 Bad Request:** Request contains a payload.
- **405 Method Not Allowed:** Unsupported HTTP methods.

## Assignment 2

## 🚀 Setup and Deployment

This section describes how to **deploy the application on a DigitalOcean Ubuntu 24.04 LTS server** using an automated shell script.

### **1️. Copy the Application Zip and Script to the Server**
Run the following `scp` commands from your local machine to transfer files to the VM:

```sh
scp -i pathofsshkeyfordo pathforappzip root@vmip:/tmp
scp -i pathofsshkeyfordo pathforscriptfile root@vmip:/
```

### **2. SSH into the VM**
Connect to the server using SSH:

```sh
ssh -i pathofsshkeyfordo root@vmip
```

### **3. Grant Execution Permission to the Script**
Once inside the VM, give execute permissions to setup.sh:

```sh
chmod +x setup.sh
```

### **4. Run the Script**
Execute the script to perform the full setup:

```sh
./setup.sh
```
This will automatically install all dependencies and start the application.

## Helpful Commands

- Run the server in the VM:
```sh
cd /opt/csye6225/webapp && sudo -u webapp_user npm run dev
```
- Run the tests in VM:
```sh
sudo -u webapp_user npm run test
```
- Check database connection in VM:
```sh
sudo systemctl status postgresql
```
- Start the database service in VM:
```sh
sudo systemctl start postgresql
```
- Stop the database service in VM:
```sh
sudo systemctl stop postgresql
```

## Assignment 3

## 🚀 Continuous Integration (CI) for Web App Application Tests

This repository is configured to run automated tests on every pull request targeting the **main** branch. The CI workflow uses GitHub Actions to:

- Spin up a PostgreSQL service (via Docker) for integration tests.
- Install Node.js and project dependencies.
- Wait for PostgreSQL to be ready.
- Run both unit and integration tests using `npm test`.

## Assignment 4

# 🚀 Packer & Custom Images - Building Custom Application Images using Packer

## Overview
This project implements **Packer** to automate machine image creation for **AWS** and **GCP**. The generated images can be deployed using **Terraform** or manually through the cloud console, allowing instances to launch with the web application pre-configured. The images are build for **Ubuntu 24.04 LTS** in **AWS DEV Account** and **GCP DEV Project**, within the default **VPC**.

## AWS Setup
Before using Packer with AWS, ensure you have the required credentials and permissions.

### Steps:
1. **Configure AWS CLI:**
   ```sh
   aws configure
   ```
   Provide AWS Access Key, Secret Key, Region, and Output format.

2. **Create an IAM Role for Packer:**
   ```sh
   aws iam create-role --role-name PackerRole --assume-role-policy-document file://trust-policy.json
   ```
   Attach necessary permissions:
   ```sh
   aws iam attach-role-policy --role-name PackerRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
   ```

3. **Setup Key Pair:**
   ```sh
   aws ec2 create-key-pair --key-name PackerKey --query 'KeyMaterial' --output text > PackerKey.pem
   chmod 400 PackerKey.pem
   ```

4. **Validate AMI Creation Permissions:**
   Ensure your IAM role has `ec2:CreateImage`, `ec2:RegisterImage`, and `ec2:DescribeImages` permissions.

## GCP Setup
Ensure you have a GCP account and the `gcloud` CLI installed.

### Steps:
1. **Authenticate GCP CLI:**
   ```sh
   gcloud auth login
   ```

2. **Set Project and Enable Compute API:**
   ```sh
   gcloud config set project <PROJECT_ID>
   gcloud services enable compute.googleapis.com
   ```

3. **Create a Service Account:**
   ```sh
   gcloud iam service-accounts create packer-sa --display-name "Packer Service Account"
   ```

4. **Assign Roles:**
   ```sh
   gcloud projects add-iam-policy-binding <PROJECT_ID> --member="serviceAccount:packer-sa@<PROJECT_ID>.iam.gserviceaccount.com" --role="roles/compute.instanceAdmin.v1"
   ```

## Packer Commands
1. **Initialize Packer:**
   ```sh
   packer init .
   ```

2. **Validate Packer Template:**
   ```sh
   packer validate packer-template.pkr.hcl
   ```

3. **Build the Image:**
   ```sh
   packer build packer-template.pkr.hcl
   ```

## Deployment Options
Once the AMI (AWS) or Image (GCP) is created, you can deploy it manually or via Terraform.

### AWS Manual Deployment:
```sh
aws ec2 run-instances --image-id <AMI_ID> --instance-type t2.micro --key-name PackerKey --security-groups default
```

### GCP Manual Deployment:
```sh
gcloud compute instances create my-instance --image=<GCP_IMAGE> --machine-type=e2-medium --zone=us-central1-a
```

# GitHub Workflow Integration

## Pull Request Triggers
- Linting and validation checks for the Packer template  
- Static code analysis for security vulnerabilities  

## Merge Triggers
- Packer builds the machine image in the development account  
- The built image is copied to the demo account for deployment 

## Assignment 5

# 🚀 Cloud Native File Management API

A cloud-native REST API for file storage and management using Node.js, Express, Sequelize, PostgreSQL, and AWS S3. The application allows users to upload, retrieve metadata, and delete files from an S3 bucket, storing metadata in a PostgreSQL database.

## Features
- Upload images to **Amazon S3**
- Store file metadata in **PostgreSQL**
- Retrieve file metadata by **ID**
- Delete files from **S3 and Database**
- Fully tested with **Unit & Integration Tests**
- **CI/CD pipeline** using **GitHub Actions**
- API follows **RESTful principles** and returns proper **HTTP status codes**

## Setup & Installation

### 1. **Clone the Repository**
```sh
git clone https://github.com/yourusername/webapp.git
cd webapp
```

### 2. **Install Dependencies**
```sh
npm install
```

### 3. **Environment Variables**
Create a `.env` file in the root directory and configure it:

```env
PORT=3000
NODE_ENV=development

# AWS S3 Credentials
AWS_REGION=your-region
S3_BUCKET=your-bucket-name

# PostgreSQL Database Config
DB_HOST=your-db-host
DB_USER=your-db-username
DB_PASSWORD=your-db-password
DB_NAME=your-db-name
DB_PORT=5432
```

## Running the Application

### **Locally**
```sh
npm run dev
```
The server will run at **http://localhost:3000**

### **Production Mode**
```sh
npm start
```

## API Endpoints

### **Upload a File**
- **POST** `/v1/file`
- Request Type: `multipart/form-data`
- Required: `file` (Only images allowed)
- **Response (201 Created)**
```json
{
  "file_name": "image.jpg",
  "id": "d290f1ee-6c54-4b01-90e6-d701748f0851",
  "url": "bucket-uuid/id/image-file.extension",
  "upload_date": "2024-03-18"
}
```

### **Retrieve File Metadata**
- **GET** `/v1/file/:id`
- **Response (200 OK)**
```json
{
  "file_name": "image.jpg",
  "id": "d290f1ee-6c54-4b01-90e6-d701748f0851",
  "url": "bucket-name/user-id/image-file.extension",
  "upload_date": "2024-03-18"
}
```
- **Response (404 Not Found)**
```json
{ "message": "File not found." }
```

### **Delete a File**
- **DELETE** `/v1/file/:id`
- Removes the file from **S3 and database**
- **Response (204 No Content)**

- **Response (404 Not Found)**
```json
{ "message": "File not found." }
```

## Assignment 6

# 🚀 Logs & Metrics

This assignment repository demonstrates a web application fully integrated with AWS CloudWatch for logging and metrics monitoring. The application is instrumented to send detailed logs and custom metrics to CloudWatch, making it easy to monitor API usage, database performance, and AWS S3 operations in real time.

## Features

- **Application Logging:**  
  - Uses **Winston** to log messages at appropriate levels (INFO for routine events, ERROR for issues).
  - Logs are written to `/opt/csye6225/webapp/logs/application.log` with UTC timestamps and include stack traces for errors.
  
- **Custom Metrics:**  
  - Uses **node-statsd** to capture custom metrics such as API call counts and timer metrics (for API calls, database queries, and AWS S3 operations).
  - Metrics are sent to a local StatsD listener on port 8125, which the CloudWatch Agent picks up and forwards to CloudWatch.

- **CloudWatch Agent Integration:**  
  - An AMI built using Packer installs and configures the Unified CloudWatch Agent.
  - The agent collects both logs and StatsD metrics as defined in `amazon-cloudwatch-agent.json` and forwards them to AWS CloudWatch for near real-time monitoring.
  
## Deployment Workflow

1. **AMI Build with Packer:**  
   - The Packer template installs and configures the CloudWatch Agent along with your web application.
   - A setup script (e.g., `setup.sh`) prepares the environment and ensures the logs directory exists and is accessible.

2. **EC2 Deployment with Terraform:**  
   - A separate Terraform repository provisions the EC2 instance using the AMI built by Packer.
   - The instance is launched with an IAM instance profile that includes the combined permissions required for S3, RDS, and CloudWatch.
   - The user data script configures environment variables, restarts the web application service, and starts the CloudWatch Agent.

3. **Validation:**  
   - **Logs:** Check that your application logs are written to `/opt/csye6225/webapp/logs/application.log` on the instance and visible in CloudWatch Logs under the designated log group (e.g., `csye6225-webapp`).
   - **Metrics:** Verify that custom metrics (such as API call counts and timer metrics) are being published in CloudWatch Metrics (e.g., under the `CWAgent` namespace).

## Running the Application

- **Local Development:**  
  Run the application via Node.js. Logs will be written to `./logs/application.log`.

- **Deployed Environment:**  
  After deployment, trigger API endpoints (e.g., file upload, health check) to generate logs and metrics. These will be forwarded to AWS CloudWatch for monitoring.

## Notes

- **Logger:**  
  The application uses Winston with appropriate log levels (INFO for normal operations and ERROR for failures) to ensure detailed and meaningful logs.
- **Metrics:**  
  Custom metrics are captured using node-statsd and forwarded to CloudWatch by the CloudWatch Agent.
- **CloudWatch Agent:**  
  The agent configuration is defined in `amazon-cloudwatch-agent.json` and is installed and configured during the AMI build via Packer.

## Assignment 8

## 🚀 CI/CD Pipeline (GitHub Actions Workflow)

This project uses GitHub Actions to implement a robust CI/CD pipeline for both **DEV** and **DEMO** AWS accounts.

### Pull Request Workflow (`on: pull_request`)
- **Runs Unit Tests** against the PR.
- **Validates Packer template.**

### Merge to Main Workflow (`on: push`)
Triggered when a pull request is merged into the `main` branch. This is the **full deployment pipeline**, which includes:

1. **Run Tests**
   - Unit tests are executed using Jest for the Node.js backend.

2. **Build Application Artifact**
   - Creates a `.zip` containing the full webapp, excluding `.git`, `.github`, `packer`, and `node_modules`.

3. **Build AMI in DEV Account**
   - Uses Packer to:
     - Launch a temporary EC2 instance.
     - Install system dependencies (Node.js, AWS CLI, unzip, jq).
     - Install app dependencies (`npm install`, etc).
     - Fetch secrets from AWS Secrets Manager and populate `.env`.
     - Enable CloudWatch Agent and start the app as a service.
   - Creates and outputs the AMI ID.

4. **Share AMI with DEMO Account**
   - Uses AWS CLI to modify AMI launch permissions for the `AWS_DEMO_ACCOUNT_ID`.

5. **Reconfigure AWS Credentials (Switch to DEMO Account)**
   - GitHub Runner re-authenticates using `AWS_DEMO_ACCESS_KEY_ID` and `AWS_DEMO_SECRET_ACCESS_KEY`.

6. **Create New Launch Template Version**
   - Creates a new version of the existing Launch Template using the latest AMI ID.

7. **Update ASG to Use Latest Launch Template**
   - Automatically updates the Auto Scaling Group (ASG) to point to the new launch template version.

8. **Trigger Instance Refresh**
   - Initiates a rolling refresh of instances within the ASG.

9. **Wait for Instance Refresh Completion**
   - Continuously polls the refresh status until it's either `Successful` or `Failed`.
   - If it fails, the GitHub Actions job fails.
   - If successful, deployment is complete.

### SSL Certificate Management

- **DEV Environment**:
  - Automatically requests a free SSL certificate via **AWS Certificate Manager (ACM)**.
  - Uses DNS validation (automated via Route53).
  
- **DEMO Environment**:
  - Uses a **manually imported SSL certificate** (e.g., from Namecheap).
  - The certificate must be imported into ACM in the DEMO account **before deployment**.
  
### GitHub Secrets Required

| Secret Name                     | Description                                       |
|--------------------------------|---------------------------------------------------|
| `AWS_ACCESS_KEY_ID`            | Access key for **DEV account**                   |
| `AWS_SECRET_ACCESS_KEY`        | Secret key for **DEV account**                   |
| `AWS_DEMO_ACCESS_KEY_ID`       | Access key for **DEMO account**                  |
| `AWS_DEMO_SECRET_ACCESS_KEY`   | Secret key for **DEMO account**                  |
| `AWS_REGION`                   | Region (e.g., `us-east-1`)                       |
| `AWS_DEMO_ACCOUNT_ID`          | Account ID of DEMO account                       |
| `AWS_ASG_NAME`                 | Name of Auto Scaling Group (same for both envs)  |
| `ENVIRONMENT`                  | Target environment: `DEV` or `DEMO`              |

# 🌐 Cloud-Native App

This repository contains a full-stack cloud-native project developed as part of a cloud computing course. It integrates a scalable Node.js web application with a secure, production-ready AWS infrastructure using Terraform and Packer. The solution is designed with CI/CD pipelines, monitoring, security best practices, and automated infrastructure provisioning.

---

## 📁 Repository Structure

```
cloud-native-app/
├── webapp/         # Node.js backend app, tests, Packer template, GitHub Actions workflows
└── tf-aws-infra/   # Terraform code to provision AWS infrastructure and automate deployment
```

---

## 🚀 Project Overview

### 1. `webapp/` – Node.js Application
- Express-based backend application with RESTful endpoints
- Health check (`/healthz`) and file management API (`/v1/file`)
- Uses PostgreSQL for persistence and AWS S3 for file storage
- Integrated with CloudWatch for logging and StatsD for metrics
- CI/CD via GitHub Actions for testing, AMI creation (Packer), and deployment workflows
- Unit and integration tests written with Jest

### 2. `tf-aws-infra/` – Infrastructure as Code (Terraform)
- Provisions full AWS setup including:
  - VPC, subnets, routing, internet gateway
  - EC2 instances (using custom AMI)
  - RDS (PostgreSQL), S3, IAM, Secrets Manager, KMS
  - Application Load Balancer (ALB), Auto Scaling Group (ASG), and Route 53 DNS
  - CloudWatch integration for logs and metrics
  - SSL configuration for HTTPS (ACM in DEV, imported cert in DEMO)
- Modular and environment-specific configurations (`dev`, `demo`)
- GitHub Actions CI to validate and lint Terraform code

---

## 🔁 CI/CD Workflow Highlights
- On Pull Request:
  - Run `terraform fmt` and `terraform validate`
  - Run tests for the web application
- On Merge to `main`:
  - Build webapp ZIP artifact
  - Create AMI with Packer (includes app and CloudWatch Agent)
  - Share AMI with DEMO account and update ASG
  - Trigger rolling instance refresh

---

## 🛡️ Security & Monitoring
- IAM roles with least-privilege permissions for EC2, S3, RDS, and Secrets Manager
- Encrypted storage for EBS, RDS, S3, and Secrets using AWS KMS (with rotation)
- CloudWatch logging using Winston + CloudWatch Agent
- Metrics collection using node-statsd and visualization via CloudWatch

---

## 📬 DNS & HTTPS
- Subdomains (e.g., `dev.soumyaganesh.me`) managed via Route 53
- HTTPS enabled via ACM (DEV) and manual cert import (DEMO)
- ALB handles traffic routing and performs health checks on `/healthz`

---

## 📦 Technologies Used
- **Languages**: Node.js, JavaScript, Shell
- **Cloud**: AWS (EC2, RDS, S3, ALB, IAM, KMS, ACM, Route 53)
- **Infrastructure**: Terraform, Packer
- **CI/CD**: GitHub Actions
- **Monitoring**: CloudWatch, StatsD

---

## 📚 Purpose
This project demonstrates how to:
- Build and deploy a secure, cloud-native app with real-time monitoring
- Automate infrastructure provisioning and scaling
- Implement CI/CD pipelines using modern DevOps tools
- Follow production-grade best practices for application and cloud architecture

---

## Conclusion
This repository showcases a complete cloud-native application with secure infrastructure, CI/CD automation, and production-ready deployment on AWS. It demonstrates best practices in DevOps, monitoring, and infrastructure-as-code.

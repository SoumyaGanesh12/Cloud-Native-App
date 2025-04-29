# IAM Role for EC2 instance (S3, RDS, and CloudWatch Agent permissions)
resource "aws_iam_role" "ec2_role" {
  name = "ec2_s3_rds_cloudwatch_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# IAM Policy for EC2 instance to access S3 and RDS
resource "aws_iam_policy" "s3_rds_policy" {
  name        = "s3_rds_access_policy"
  description = "Allows EC2 to access S3, RDS and Secrets Manager"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        Resource = "arn:aws:s3:::${random_uuid.s3_bucket_uuid.result}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:Connect"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}

# Attach the S3/RDS policy to the combined role
resource "aws_iam_role_policy_attachment" "attach_s3_rds_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_rds_policy.arn
}

# Attach the AWS Managed CloudWatch Agent policy to the same role
resource "aws_iam_role_policy_attachment" "attach_cloudwatch_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Create IAM Instance Profile for the combined role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "csye6225_ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}

# Secret manager policy
resource "aws_iam_policy" "secrets_access_policy" {
  name        = "ec2_secretsmanager_access"
  description = "Allows EC2 to read DB secret and decrypt with KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}

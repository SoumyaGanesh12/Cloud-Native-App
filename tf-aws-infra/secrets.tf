resource "random_password" "db_password" {
  length           = var.db_password_length
  special          = var.db_password_special
  override_special = var.db_password_override_special
}

resource "random_string" "secret_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "rds-db-password-${random_string.secret_suffix.result}"
  description = "DB password used by the web application"
  kms_key_id  = aws_kms_key.secrets_key.arn
  tags = {
    Name = "rds-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    password = random_password.db_password.result
  })
}
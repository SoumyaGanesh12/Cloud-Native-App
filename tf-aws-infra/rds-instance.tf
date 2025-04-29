resource "aws_db_instance" "database_instance" {
  allocated_storage = 20
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  identifier        = var.db_identifier
  username          = var.db_username
  # password               = var.db_password
  # Use random generated password for db
  password               = random_password.db_password.result
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az
  db_name                = var.db_name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id] # Security groups for the RDS instance
  parameter_group_name   = aws_db_parameter_group.rds_param_group.name     # Attach custom parameter group
  # Attach kms key for encryption
  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn
  tags = {
    Name = "csye6225-rds-instance"
  }
}

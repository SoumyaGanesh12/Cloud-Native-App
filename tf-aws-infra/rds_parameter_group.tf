resource "aws_db_parameter_group" "rds_param_group" {
  name   = var.db_parameter_group_name
  family = "postgres${var.db_engine_version}" # Dynamically set family based on version

  # Log database activity
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  # Disable SSL enforcement to allow non-SSL connections
  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }

  tags = {
    Name = "database_parameter_group"
  }
}

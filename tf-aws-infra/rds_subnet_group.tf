resource "aws_db_subnet_group" "database_subnet_group" {
  name = "csye6225-db-subnet-group"

  # Automatically reference all dynamically created private subnets
  subnet_ids = aws_subnet.private_subnets[*].id

  tags = {
    Name = "database_subnet_group"
  }
}

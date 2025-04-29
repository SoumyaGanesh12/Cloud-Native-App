# Creates Public & Private Subnets

# Fetch available availability zones dynamically
data "aws_availability_zones" "available" {}

# Create Public Subnets Dynamically
resource "aws_subnet" "public_subnets" {
  # Defines how many public subnets to create
  count = var.num_public_subnets

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, var.subnet_mask, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnet_prefix}-Public-Subnet-${count.index + 1}"
  }
}

# Create Private Subnets Dynamically
resource "aws_subnet" "private_subnets" {
  # Defines how many private subnets to create
  count = var.num_private_subnets

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, var.subnet_mask, count.index + var.num_public_subnets)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.subnet_prefix}-Private-Subnet-${count.index + 1}"
  }
}

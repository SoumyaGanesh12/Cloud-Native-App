# Creates Route Tables & Associations

# Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-Public-RT"
  }
}

# Attach Public Subnets to the Public Route Table
resource "aws_route_table_association" "public_assoc" {
  count = var.num_public_subnets

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Create Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-Private-RT"
  }
}

# Attach Private Subnets to the Private Route Table
resource "aws_route_table_association" "private_assoc" {
  count = var.num_private_subnets

  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

# Create Public Route for Internet Access
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0" # Allow all internet traffic
  gateway_id             = aws_internet_gateway.igw.id
}

# create a custom route table for public subnets
# public subnets can reach to the internet by using this
resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.prod-vpc.id
  route {
    cidr_block = "0.0.0.0/0"                      # associated subnet can reach everywhere
    gateway_id = aws_internet_gateway.prod-igw.id # CRT uses this IGW to reach internet
  }

  tags = {
    Name = "iForm Public Route Table"
  }
}

# create a custom route table for private subnets
# subnets can reach to the internet by using NAT gateway
resource "aws_route_table" "prod-private-crt" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "iForm Private Route Table"
  }
}

# route table association for the private subnets
resource "aws_route_table_association" "prod-crta-private-subnet" {
  subnet_id      = aws_subnet.prod-subnet-private.id
  route_table_id = aws_route_table.prod-private-crt.id
}
resource "aws_route_table_association" "prod-crta-private-2-subnet" {
  subnet_id      = aws_subnet.prod-subnet-private-2.id
  route_table_id = aws_route_table.prod-private-crt.id
}

# route table association for the public subnets
resource "aws_route_table_association" "prod-crta-public-subnet" {
  subnet_id      = aws_subnet.prod-subnet-public.id
  route_table_id = aws_route_table.prod-public-crt.id
}
resource "aws_route_table_association" "prod-crta-public-2-subnet" {
  subnet_id      = aws_subnet.prod-subnet-public-2.id
  route_table_id = aws_route_table.prod-public-crt.id
}

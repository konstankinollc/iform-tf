resource "aws_vpc" "prod-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false
  instance_tenancy     = "default"

  tags = {
    Name = "iForm VPC"
  }
}

resource "aws_subnet" "prod-subnet-private" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true # it makes this a private subnet

  tags = {
    Name = "iForm Private Subnet"
  }
}

resource "aws_subnet" "prod-subnet-private-2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false # it makes this a private subnet
  availability_zone       = "us-east-1c"

  tags = {
    Name = "iForm Private Subnet"
  }
}

resource "aws_subnet" "prod-subnet-private-3" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false # it makes this a private subnet
  availability_zone       = "us-east-1a"

  tags = {
    Name = "iForm Private DB Targeted Subnet"
  }
}

resource "aws_subnet" "prod-subnet-public" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = true # it makes this a public subnet
  availability_zone       = "us-east-1a"

  tags = {
    Name = "iForm Public Subnet"
  }
}

resource "aws_subnet" "prod-subnet-public-2" {
  vpc_id                  = aws_vpc.prod-vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = true # it makes this a public subnet
  availability_zone       = "us-east-1b"

  tags = {
    Name = "iForm Public Subnet"
  }
}

# create an IGW (Internet Gateway)
# It enables your vpc to connect to the internet
resource "aws_internet_gateway" "prod-igw" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    Name = "iForm Internet Gateway"
  }
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat" {
  depends_on    = [aws_internet_gateway.prod-igw]
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.prod-subnet-public.id
}

# output "nat_gateway_ip" {
#   value = aws_eip.nat.public_ip
# }

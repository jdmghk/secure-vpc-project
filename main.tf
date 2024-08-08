provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

#Public Subnets (2 for high availability)
resource "aws_subnet" "public_subnet_a" {
  vpc_id    = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id    = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true
}

#Private Subnets (2 for high availabity)
resource "aws_subnet" "private_subnet_a" {
  vpc_id    = aws_vpc.my_vpc.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id    = aws_vpc.my_vpc.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_nat_gateway" "my_nat" {
  allocation_id = aws_eip.nat_eip.id # Create an Elastic IP below
  subnet_id = aws_subnet.public_subnet_a.id


tags = {
  Name = "gw NAT"
}
depends_on = [aws_internet_gateway.my_igw]
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

#Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

#Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.my_nat.id
  }
}

#Associate Public Subnets with the Public Route TABLE
resource "aws_route_table_association" "public_rta_a" {
  subnet_id = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rta_b" {
  subnet_id = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

#Associate Private Subnets with the Private Route Table
resource "aws_route_table_association" "private_rta_a" {
  subnet_id = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rta_b" {
  subnet_id = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}


#Web Server Security Group (Allow HTTP on port 80)
resource "aws_security_group" "web_sg" {
  name  = "web_server_sg"
  vpc_id = aws_vpc.my_vpc.id


  ingress  {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere
  }

  egress  {
    from_port = 0
    to_port   = 0
    protocol  = "-1" #All protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow to anywhere
  }
}
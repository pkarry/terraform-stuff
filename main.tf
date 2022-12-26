locals {
  vpc_name                 = "custom-vpc-1"
  private_subnet_name      = format("%s-%s", trim("${var.private_subnet_range}", "/24"), var.private_subnet_az)
  public_subnet_name       = format("%s-%s", trim("${var.public_subnet_range}", "/24"), var.public_subnet_az)
  internet_gw_name         = "custom-igw"
  nat_gw_name              = "custom-nat"
  public_route_table_name  = "custom-public-route"
  private_route_table_name = "custom-private-route"
}

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_range
  instance_tenancy = "default"

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = local.vpc_name
  }
}

resource "aws_subnet" "private_sub" {
  #count      = "${length(local.public_subnets)}" ## If multiple subnets are provided
  #cidr_block = "${element(values(local.public_subnets), count.index)}" ## If multiple subnets are provided
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_range
  availability_zone = var.private_subnet_az
  #availability_zone = "${element(keys(local.public_subnets), count.index)}" ## If multiple subnets are provided

  tags = {
    Name = local.private_subnet_name
  }
}

resource "aws_subnet" "public_sub" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_range
  availability_zone       = var.public_subnet_az
  map_public_ip_on_launch = true

  tags = {
    Name = local.public_subnet_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = local.internet_gw_name
  }
}

## Create Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true

  depends_on = [aws_internet_gateway.igw]
}

## Create NAT Gateway and attach EIP
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_sub.id

  tags = {
    Name = local.nat_gw_name
  }

  depends_on = [aws_internet_gateway.igw]
}

## Route Table Associations
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = local.public_route_table_name
  }
}

resource "aws_default_route_table" "private_route" {
  default_route_table_id = aws_vpc.main.main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = local.private_route_table_name
  }
}

resource "aws_route" "add_igw_to_route" {
  route_table_id         = aws_default_route_table.private_route.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "igw_assoc" {
  #count          = "${length(local.public_subnets)}"  ## If multiple subnets are provided
  #subnet_id      = "${element(aws_subnet.private_sub.*.id, count.index)}" ## If multiple subnets are provided
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_default_route_table.private_route.id
}

resource "aws_route_table_association" "nat_assoc" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_route.id
}

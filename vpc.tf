# VPC for our applications
resource "aws_vpc" "vpc-main" {
  cidr_block       = "${var.vpc_cidr}"
  enable_dns_hostnames = true

  tags {
    Name = "VPC-MAIN"
  }
}

# Create Internet Gateway and attached it to javahome_vpc
resource "aws_internet_gateway" "igw-main" {
  vpc_id = "${aws_vpc.vpc-main.id}"
  tags {
    Name = "IGW-MAIN"
  }
}

# Build subnets for our VPCs
resource "aws_subnet" "public" {
  count = "${length(var.subnets_cidr)}"
  vpc_id = "${aws_vpc.vpc-main.id}"
  availability_zone = "${element(var.azs,count.index)}"
  cidr_block = "${element(var.subnets_cidr,count.index)}"
  map_public_ip_on_launch = true
  tags {
    Name = "Subnet-${count.index +1}"
  }
}

# Create Route table, attach Internet Gateway and associate with public subnets
resource "aws_route_table" "public_rt" {
  vpc_id = "${aws_vpc.vpc-main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw-main.id}"
  }
  tags {
    Name = "PublicRT"
  }
}

# Attach route table with public subnets
resource "aws_route_table_association" "associate" {
  count = "${length(var.subnets_cidr)}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public_rt.id}"
}



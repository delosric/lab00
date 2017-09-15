terraform {
  backend "s3" {
    bucket = "lab01-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_vpc" "WWW" {
  cidr_block = "172.23.0.0/16"

  tags {
    Name = "WWW"
  }
}

resource "aws_subnet" "AZa" {
  vpc_id                  = "${aws_vpc.WWW.id}"
  cidr_block              = "172.23.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = "true"

  tags {
    Name = "AZa"
  }
}

resource "aws_subnet" "AZb" {
  vpc_id                  = "${aws_vpc.WWW.id}"
  cidr_block              = "172.23.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = "true"

  tags {
    Name = "AZb"
  }
}

resource "aws_internet_gateway" "IGW" {
  vpc_id = "${aws_vpc.WWW.id}"

  tags {
    Name = "IGW"
  }
}

resource "aws_route_table" "RT" {
  vpc_id = "${aws_vpc.WWW.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW.id}"
  }

  tags {
    Name = "RT"
  }
}

resource "aws_route_table_association" "ASSa" {
  subnet_id      = "${aws_subnet.AZa.id}"
  route_table_id = "${aws_route_table.RT.id}"
}

resource "aws_route_table_association" "ASSb" {
  subnet_id      = "${aws_subnet.AZa.id}"
  route_table_id = "${aws_route_table.RT.id}"
}

output "WWW_id" {
  value = "${aws_vpc.WWW.id}"
}

output "AZa_id" {
  value = "${aws_subnet.AZa.id}"
}

output "AZb_id" {
  value = "${aws_subnet.AZb.id}"
}

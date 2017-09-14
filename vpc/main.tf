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
  vpc_id            = "${aws_vpc.WWW.id}"
  cidr_block        = "172.23.1.0/24"
  availability_zone = "eu-west-1a"

  tags {
    Name = "AZa"
  }
}

resource "aws_subnet" "AZb" {
  vpc_id            = "${aws_vpc.WWW.id}"
  cidr_block        = "172.23.2.0/24"
  availability_zone = "eu-west-1b"

  tags {
    Name = "AZb"
  }
}

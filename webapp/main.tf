terraform {
  backend "s3" {
    bucket = "lab01-tfstate"
    key    = "webapp/terraform.tfstate"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "terraform_remote_state" "WWW" {
  backend = "s3"

  config {
    bucket = "lab01-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}

resource "aws_instance" "web" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  key_name               = "GSK.key"
  vpc_security_group_ids = ["${aws_security_group.sgWEB.id}"]
  user_data              = "${data.template_file.USERDATA.rendered}"
  subnet_id              = "${data.terraform_remote_state.WWW.AZa_id}"

  tags {
    Name = "HelloWorld"
  }
}

resource "aws_security_group" "sgWEB" {
  name        = "sgWEB"
  description = "Allow SSH and HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = "${data.terraform_remote_state.WWW.WWW_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "USERDATA" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    username = "Guillaume"
  }
}

output "publicip" {
  value = "${aws_instance.web.public_ip}"
}

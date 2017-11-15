provider "aws" {
  region = "eu-west-1"
}

variable environment {
  default = "dev"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data template_file "userdata" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    username = "CRC"
  }
}

resource "aws_instance" "web" {
  ami                    = "${data.aws_ami.ubuntu.id}"
  instance_type          = "t2.micro"
  key_name               = "gitcrc"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id              = "${element(data.terraform_remote_state.CoreInfra.subnet_ids,0)}"
  user_data              = "${data.template_file.userdata.rendered}"

  tags {
    Name = "webapp-${var.environment}"
  }
}

resource "aws_security_group" "web" {
  name        = "ssh_and_http"
  description = "Allow inbound traffic"
  vpc_id      = "${data.terraform_remote_state.CoreInfra.vpc_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

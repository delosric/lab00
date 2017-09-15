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

data "terraform_remote_state" "WWW" {
  backend = "s3"

  config {
    bucket = "lab01-tfstate"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}


resource "aws_security_group" "sgWEB" {
  name        = "sgWEB"
  description = "Allow SSH and HTTP"
  vpc_id      = "${data.terraform_remote_state.WWW.WWW_id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = ["${aws_security_group.sgELB.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sgELB" {
  name        = "sgELB"
  description = "Allow HTTP"
  vpc_id      = "${data.terraform_remote_state.WWW.WWW_id}"

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

resource "aws_elb" "ELB" {
  name            = "ELBWEB"
  security_groups = ["${aws_security_group.sgELB.id}"]
  subnets         = ["${data.terraform_remote_state.WWW.subnets}"]
  internal        = false

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 2
    target              = "HTTP:80/"
    interval            = 5
  }
}

data "template_file" "USERDATA" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    username = "Guillaume"
  }
}

resource "aws_launch_configuration" "LC" {
  name_prefix     = "LC"
  key_name        = "GSK.key"
  image_id        = "${var.ami_id}"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.sgWEB.id}"]

  lifecycle {
    create_before_destroy = "true"
  }
}

resource "aws_autoscaling_group" "ASG" {
  name                 = "ASG-${aws_launch_configuration.LC.name}"
  launch_configuration = "${aws_launch_configuration.LC.name}"
  load_balancers       = ["${aws_elb.ELB.id}"]
  vpc_zone_identifier  = ["${data.terraform_remote_state.WWW.subnets}"]

  min_size                  = 2
  max_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"

tags = [
{
key = "Name"
value = "autoscaleserver"
propagate_at_launch = "true"
}
]


  lifecycle {
    create_before_destroy = "true"
  }
}

#output "publicip" {
#  value = "${aws_instance.web.public_ip}"
#}

output "ELBDNS" {
value = "${aws_elb.ELB.dns_name}"
}

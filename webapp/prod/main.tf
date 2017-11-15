provider "aws" {
}

# Create a new instance of the latest Ubuntu 14.04 on an
# t2.micro node with an AWS Tag naming it "HelloWorld"

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

resource "aws_elb" "web_elb" {
  name            = "web-elb"
  subnets         = ["${data.terraform_remote_state.coreinfra.subnets}"]
  security_groups = ["${aws_security_group.allow_ssh.id}"]

  ## Loadbalancer configuration

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

resource "aws_launch_configuration" "web" {
  name          = "web_server_config"
  image_id      = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  user_data              = "${data.template_file.webapp.rendered}"
  security_groups        = ["${aws_security_group.allow_ssh.id}"]
  key_name               = "MY_KEY"
}


resource "aws_autoscaling_group" "web" {
  name                 = "asb-web"
  launch_configuration = "${aws_launch_configuration.web.name}"
  load_balancers       = ["${aws_elb.web_elb.id}"]
  vpc_zone_identifier = ["${data.terraform_remote_state.coreinfra.subnets}"]
  min_size             = 2
  max_size             = 2
  health_check_type = "EC2"
  health_check_grace_period = "300"

  lifecycle {
    create_before_destroy = true
  }
}

data template_file "webapp" {
  template = "${file("${path.module}/userdata.tpl")}"

  vars {
    username = "JE SUIS USER"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_all"
  description = "Allow ssh trafic"
  vpc_id      = "${data.terraform_remote_state.coreinfra.vpc_id}"

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

output "elb_dns" {
  value = ["${aws_elb.web_elb.dns_name}"]
}


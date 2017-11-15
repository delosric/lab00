terraform {
  backend "s3" {
    bucket = "labcrc1"
    key    = "lab/webapp-lab.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "CoreInfra" {
  backend = "s3"

  config {
    bucket = "labcrc1"
    key    = "vpc/terraform.tfstate"
    region = "eu-west-1"
  }
}

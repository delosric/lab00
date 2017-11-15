terraform {
  backend "s3" {
    bucket = "flams-admin"
    key    = "d2si/lab/webapp-lab.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "coreInfra" {
  backend = "s3"

  config {
    bucket = "flams-admin"
    key    = "d2si/lab/coreInfra.tfstate"
    region = "eu-west-1"
  }
}

terraform {
  backend "s3" {
    bucket = "mon-bucket-name"
    key    = "lab/webapp.tfstate"
    region = "eu-west-1"
  }
}

data "terraform_remote_state" "coreInfra" {
  backend = "s3"

  config {
    bucket = "mon-bucket-name"
    key    = "lab/coreInfra.tfstate"
    region = "eu-west-1"
  }
}

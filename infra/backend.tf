terraform {
  backend "s3" {
    bucket = "a-super-ultra-secure-company-terraform"
    key    = "a-super-ultra-secure-company.tfstate"
    region = "eu-south-1"
  }
}
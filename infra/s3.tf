resource "aws_s3_bucket" "asdda-deployments" {
  bucket = "${var.company}-asdda-deployments"
}
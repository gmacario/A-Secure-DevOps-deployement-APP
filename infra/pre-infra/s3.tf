resource "aws_s3_bucket" "terraform" {
  bucket = "${var.company}-terraform"
}
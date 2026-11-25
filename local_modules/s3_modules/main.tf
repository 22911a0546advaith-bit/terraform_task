resource "aws_s3_bucket" "test_s3_terraform" {
  bucket = var.bucket_name
  tags   = var.bucket_tags
}
variable "bucket_name" {
  description = "Name of the S3 bucket (must be globally unique)."
  type        = string
}

variable "bucket_tags" {
  description = "Tags on the S3 bucket."
  type        = map(string)
}
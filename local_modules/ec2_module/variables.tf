variable "ami_id" {
  description = "The AMI ID for the EC2 instance."
  type        = string
}

variable "instance_type" {
  description = "The instance type for the EC2 instance."
  type        = string
}

variable "instance_name" {
  description = "Name tag of the EC2 instance."
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID for the EC2 instance."
  type        = string
}

variable "security_group_id" {
  description = "The security group ID for the EC2 instance."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the bucket the instance role can access."
  type        = string
}

variable "iam_role_name" {
  description = "Name of the IAM role."
  type        = string
}

variable "iam_policy_name" {
  description = "Name of the IAM role policy."
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile."
  type        = string
}

variable "s3_object_actions" {
  description = "S3 actions allowed on the objects in the bucket."
  type        = list(string)
}

variable "role_tags" {
  description = "Tags on the IAM role."
  type        = map(string)
}
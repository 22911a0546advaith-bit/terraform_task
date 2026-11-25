resource "aws_instance" "test_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  iam_instance_profile   = aws_iam_instance_profile.test_tf_profile_ec2.name

  tags = {
    Name = var.instance_name
  }
}


#iam role 
resource "aws_iam_role" "test_tf_ec2_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = var.role_tags
}

resource "aws_iam_role_policy" "test_s3_access" {
  name = var.iam_policy_name
  role = aws_iam_role.test_tf_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = var.bucket_arn
      },
      {
        Effect   = "Allow"
        Action   = var.s3_object_actions
        Resource = "${var.bucket_arn}/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "test_tf_profile_ec2" {
  name = var.iam_instance_profile_name
  role = aws_iam_role.test_tf_ec2_role.name
}
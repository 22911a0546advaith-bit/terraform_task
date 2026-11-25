 
 #vpc variables
 variable "root_vpc_name" {
   default = "test_vpc_terraform"
 }
 variable "root_cidr" {
   default = "10.0.0.0/16"
 }
 variable "subnet_cidr" {
   default = "10.0.1.0/24"
 }
 variable "map_public_ip" {
   default = true
 }
 variable "security_group_name" {
   default = "allow_tls"
 }
 variable "security_group_description" {
   default = "Allow TLS inbound traffic and all outbound traffic"
 }
 variable "ingress_port" {
   default = [22]
 }
 variable "ingress_protocol" {
   default = "tcp"
 }
 variable "ingress_cidr_ipv4" {
   default = "10.0.0.0/16"
 }
 variable "egress_cidr_ipv4" {
   default = "0.0.0.0/0"
 }
 variable "egress_cidr_ipv6" {
   default = "::/0"
 }
 variable "egress_protocol" {
   default = "-1"
 }
 variable "igw_name" {
   default = "test_gateway_for_test_vpc"
 }
 variable "route_table_name" {
   default = "test_route_table"
 }
 variable "public_route_cidr" {
   default = "0.0.0.0/0"
 }

#S3 variables 




variable "bucket_name" {
  default = "test-bucket-teraform1233212321"
}

variable "bucket_tags" {
  default = {
    Name        = "My bucket"
    Environment = "fun"
  }
}

#ec2 variables 



variable "ami_id" {
  default = "ami-09853ee25db7186f2"
}
variable "instance_type" {
  default = "t3.micro"
}
variable "instance_name" {
  default = "test_instance"

  #iam
}
variable "iam_role_name" {
  default = "test_role"
}
variable "iam_policy_name" {
  default = "test_s3_terrform_policy"
}
variable "iam_instance_profile_name" {
  default = "test_ec2_profile"
}
variable "s3_object_actions" {
  default = ["s3:GetObject", "s3:PutObject"]
}
variable "role_tags" {
  default = {
    tag-key = "tag-value"
  }
}

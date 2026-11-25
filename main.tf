module "test_root_vpc" {
  source =  "./local_modules/vpc_module"

  vpc_name                   = var.root_vpc_name
  vpc_cidr                   = var.root_cidr
  subnet_cidr                = var.subnet_cidr
  map_public_ip              = var.map_public_ip
  security_group_name        = var.security_group_name
 security_group_description  = var.security_group_description
  ingress_port               = var.ingress_port
  ingress_protocol           = var.ingress_protocol
  ingress_cidr_ipv4          = var.ingress_cidr_ipv4
  egress_cidr_ipv4           = var.egress_cidr_ipv4
  egress_cidr_ipv6           = var.egress_cidr_ipv6
  egress_protocol            = var.egress_protocol
  igw_name                   = var.igw_name
  route_table_name           = var.route_table_name
  public_route_cidr          = var.public_route_cidr
}

module "test_root_s3" {
  source =  "./local_modules/s3_modules"

  bucket_name = var.bucket_name
  bucket_tags = var.bucket_tags
}

module "test_root_ec2" {
  source = "./local_modules/ec2_module"

  ami_id                    = var.ami_id 
  instance_type             = var.instance_type
  instance_name             = var.instance_name
  subnet_id                 = module.test_root_vpc.subnet_id
  security_group_id         = module.test_root_vpc.securitygroup_id
  bucket_arn                = module.test_root_s3.bucket_arn
  iam_role_name             = var.iam_role_name
  iam_policy_name           = var.iam_policy_name
  iam_instance_profile_name = var.iam_instance_profile_name
  s3_object_actions         = var.s3_object_actions
  role_tags = var.role_tags
}
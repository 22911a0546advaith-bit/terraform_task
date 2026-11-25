# terraform_task
Terraform Local Modules: VPC, EC2 and S3

This is how I built a small AWS setup in Terraform using local modules. I split it into three modules (VPC, EC2, S3) and called all of them from one root main.tf. Region used: eu-north-1.the modules have no hardcoded values and no defaults. Every detail (names, CIDR blocks, ports, AMI, instance type, bucket name) is a variable inside the module. The default values live in one place, the root variables.tf, and the root main.tf passes them into the modules. For each environment (dev, QA, prod) I override only what differs in its own .tfvars file. To change anything I only edit variables.tf or a .tfvars file. The one exception is the region, which stays in the root providers.tf.
What I built
•	A VPC with a public subnet, internet gateway, route table and a security group
•	An EC2 instance inside that subnet
•	An S3 bucket in its own module
•	An IAM role so the EC2 instance can read and write to that bucket
Step 1: Set up the folder structure
I could have put everything in one big main.tf, but I wanted to learn how modules work. Splitting the network, the storage and the server into their own modules keeps each part small and easy to read, and I can reuse a module later without copying code. I used the same four files in every module so I always know where to look.
I created a project folder called terraform_task and put each module in its own folder inside local_modules:
terraform_task/
├── main.tf              (root: calls all the modules)
├── variables.tf         (root: holds every value as a default)
├── providers.tf         (root: AWS provider + region)
├── dev.tfvars           (values for the dev environment)
├── qa.tfvars            (values for the QA environment)
├── prod.tfvars          (values for the prod environment)
├── local_modules/
│   ├── vpc_module/      (main.tf, variables.tf, outputs.tf, providers.tf)
│   ├── ec2_module/      (main.tf, variables.tf, providers.tf)
│   └── s3_modules/      (main.tf, variables.tf, outputs.tf, providers.tf)
├── .terraform.lock.hcl
├── terraform.tfstate
└── terraform.tfstate.backup
I kept the same file pattern in every module so it is easy to find things: main.tf for resources, variables.tf for inputs, outputs.tf for values other modules need, and providers.tf for the provider requirement.
Step 2: Configure the provider in the root
Terraform needs to know which cloud and region to build in. I set the region once in the root so I don't have to repeat it in every module. The modules only declare which provider they need, so they don't pick a region themselves and can be reused anywhere.
In the root providers.tf I set the AWS provider and the region:
provider "aws" {
  region = "eu-north-1"
}
Step 3: Build the VPC module
The server needs a network of its own to live in, so the VPC module builds that. The subnet is the slice of the network the instance sits in. The internet gateway, route table and route table association are what make that subnet public, and the security group is the firewall around the instance. I made every value a variable so the same module can build dev, QA and prod without editing it. I added outputs because modules can't see each other's resources, so the EC2 module can only get the subnet and security group if the VPC module hands them out.
In local_modules/vpc_module/variables.tf I declared one variable for every detail of the network. None of them has a default, so the root main.tf has to supply all of them.
Variable	What it sets
vpc_name	Name tag of the VPC
vpc_cidr	CIDR block of the VPC
subnet_cidr	CIDR block of the subnet
map_public_ip	Whether instances in the subnet get a public IP (true/false)
security_group_name	Name of the security group
security_group_description	Description of the security group
ingress_port	Inbound port that is allowed (used as both from and to)
ingress_protocol	Inbound protocol, like tcp
ingress_cidr_ipv4	Who is allowed to connect inbound
egress_cidr_ipv4	Outbound IPv4 destination
egress_cidr_ipv6	Outbound IPv6 destination
egress_protocol	Outbound protocol (-1 means all)
igw_name	Name tag of the internet gateway
route_table_name	Name tag of the route table
public_route_cidr	Destination of the route that points to the internet gateway




In main.tf the resources are the same as before (VPC, subnet, security group with its ingress and egress rules, internet gateway, route table, route table association), but every value now comes from a variable:
# VPC: the private network that everything else lives in.
# The CIDR range and the name both come from the root main.tf.
resource "aws_vpc" "test_vpc_terraform" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}
Step 4: Build the S3 module
The bucket is a separate thing from the server and the network, so it gets its own module. That way I can create or change a bucket without touching the EC2 code. It outputs the bucket ARN because the EC2 module needs to know which bucket it is allowed to use.
The S3 module only needs two inputs: bucket_name (string) and bucket_tags (a map of strings). I kept it in its own module so I can attach a different bucket later without touching the EC2 code.
# S3 bucket: storage the EC2 instance will read from and write to.
# The name must be globally unique, and both name and tags come from the root main.tf.
resource "aws_s3_bucket" "test_s3_terraform" {
  bucket = var.bucket_name
  tags   = var.bucket_tags
}
Step 5: Build the EC2 module
The instance needs to read and write the bucket, but I don't want to store access keys on it. An IAM role gives it temporary permissions instead. The role policy limits it to just that one bucket and only the actions it needs. An instance can't take a role directly, so I wrapped the role in an instance profile and attached that to the instance. The subnet, security group and bucket ARN are variables because they come from the other two modules.
The EC2 module has the same four resources as before (instance, IAM role, role policy, instance profile), and again every detail is a variable with no default:
Variable	What it sets
ami_id	AMI of the instance
instance_type	Instance type, like t3.micro
instance_name	Name tag of the instance
subnet_id	Subnet to launch in (from the VPC module)
security_group_id	Security group to attach (from the VPC module)
bucket_arn	Bucket the role can access (from the S3 module)
iam_role_name	Name of the IAM role
iam_policy_name	Name of the role policy
iam_instance_profile_name	Name of the instance profile
s3_object_actions	List of S3 actions allowed on the objects in the bucket
role_tags	Tags on the IAM role

The policy keeps two separate statements on purpose: s3:ListBucket applies to the bucket ARN, while the object actions apply to everything inside it (bucket_arn/*).
# Role policy: what the EC2 role is allowed to do in S3.
# Listing applies to the bucket itself; the object actions (set in the root) apply to what is inside it.
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
Step 6: Fill in the values and call the modules from the root
variables.tf: I wanted the actual values (CIDRs, names, AMI, instance type) in one place, separate from the code that builds things. That way main.tf only describes how the modules connect, and when I want to change something I open variables.tf and leave the module calls alone. It also means values can be overridden later, from a .tfvars file or with -var, which I needed for the different environments. The modules have no defaults on purpose, so nothing is hidden inside them and every value has to be passed in from the root  .  main.tf this way: It is the file that connects the three modules. Passing the VPC and S3 outputs into the EC2 module also tells Terraform the order to build things in, so the network and the bucket exist before the instance.
All the values live in the root variables.tf as defaults, so that is the file I edit when I want to change something. The root main.tf calls the three modules and passes each value in with var.<name>. For example, in variables.tf:
variable "root_cidr" {
  default = "10.0.0.0/16"
}



And in main.tf the VPC module gets it with vpc_cidr = var.root_cidr. The full main.tf looks like this:
# Network: creates the VPC, subnet, security group, internet gateway and routing.
# Every value the VPC module needs is passed in here from variables.tf.
module "test_root_vpc" {
  source = "./local_modules/vpc_module"

  vpc_name                   = var.root_vpc_name
  vpc_cidr                   = var.root_cidr
  subnet_cidr                = var.subnet_cidr
  map_public_ip              = var.map_public_ip
  security_group_name        = var.security_group_name
  security_group_description = var.security_group_description
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

# Storage: creates the S3 bucket. Its ARN is passed on to the EC2 module below.
module "test_root_s3" {
  source = "./local_modules/s3_modules"

  bucket_name = var.bucket_name
  bucket_tags = var.bucket_tags
}

# Compute: creates the EC2 instance and the IAM role that lets it use the bucket.
# The subnet, security group and bucket ARN come from the two modules above,
# which is why Terraform builds those first.
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
  role_tags                 = var.role_tags
}
Two things to remember here. A module's source has to be a literal path, it can't be a variable, so the three paths are written directly. And because EC2 uses outputs from the other two modules, Terraform automatically creates the VPC and S3 bucket first, then the EC2 instance. If I forget to pass a value in main.tf, terraform plan stops and tells me which argument is missing.
Step 7: Create a .tfvars file for each environment
I want to run the same code for dev, QA and prod, but with different names, CIDRs and so on. Instead of editing variables.tf every time, I keep one small file per environment with only the values that differ, and everything else falls back to the defaults. I pass the file myself with -var-file so I always choose on purpose which environment I'm building.
I have three environments, dev, QA and prod, so I created one .tfvars file for each in the root folder. The extension is .tfvars, not .tfvar. In each file I only put the values that differ. Anything I leave out falls back to the default in variables.tf. This is dev.tfvars:
root_vpc_name             = "dev_vpc"
root_cidr                 = "10.0.0.0/16"
subnet_cidr               = "10.0.1.0/24"
instance_type             = "t3.micro"
instance_name             = "dev_instance"
bucket_name               = "myapp-dev-bucket-123456"
iam_role_name             = "dev_role"
iam_policy_name           = "dev_s3_policy"
iam_instance_profile_name = "dev_ec2_profile"
bucket_tags = {
  Name        = "Dev bucket"
  Environment = "dev"
}
•	Bucket names can only use lowercase letters, numbers and hyphens. Uppercase letters give an InvalidBucketName error.
•	Bucket names are global. They are shared by every AWS account, so a generic name like myapp-dev-bucket-123456 may already be taken and fail with BucketAlreadyExists. I add my own name or some random digits to make it unique.
•	IAM names (role, policy, instance profile) must be unique in the account, so every environment has its own.
•	CIDRs for different environments can overlap as long as the VPCs are never connected to each other. Using different ranges (like 10.0, 10.1, 10.2) is safer if I connect them later.
•	ingress_cidr_ipv4 is not in these files, so it uses the default 10.0.0.0/16. If an environment's root_cidr changes, I add a matching ingress_cidr_ipv4 to its file.
•	Terraform does not load these files by itself. It only loads terraform.tfvars and *.auto.tfvars automatically, so I pass the one I want with -var-file.
•	All the files share one state. Applying a different .tfvars file later changes the infrastructure already built from the first one. It does not create a second set next to it.
Step 8: Run Terraform
The order matters. init sets up the provider and modules first, validate catches mistakes before anything touches AWS, and plan shows me exactly what will happen so I can check it before apply builds it.
From the root folder (terraform_task). I run init and validate once, and again whenever I add a new module:
terraform init
terraform validate
Then I plan and apply with the file for the environment I want. This is dev:
terraform plan  -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
For QA or prod I use qa.tfvars or prod.tfvars instead.
•	init downloads the AWS provider and registers the local modules.
•	plan shows what will be created. I read it before applying and watch for -/+ (replace) or destroy lines, which mean an existing resource will be replaced or removed.
•	apply creates everything in AWS.
•	If an apply fails halfway (for example BucketAlreadyExists), Terraform does not roll back. It keeps what it already built in the state, so after I fix the problem the next apply only creates the remaining resources.
Step 9: Clean up
When I'm done, I remove everything so nothing keeps running:
terraform destroy -var-file="dev.tfvars"
CONCLUSION
In this project I built a small AWS setup with Terraform using local modules: a VPC with a public subnet, an EC2 instance, an S3 bucket, and an IAM role that lets the instance use the bucket.
I split the work into three modules (VPC, EC2 and S3) and called them from one root main.tf. The modules have no hardcoded values or defaults. Every detail is a variable, the default values live in the root variables.tf, and a separate .tfvars file for dev, QA and prod overrides what differs for each environment.
 

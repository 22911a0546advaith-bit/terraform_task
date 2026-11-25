variable "vpc_name" {
  description = "Name tag of the VPC."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block of the subnet."
  type        = string
}

variable "map_public_ip" {
  description = "Whether instances launched in the subnet get a public IP."
  type        = bool
}

variable "security_group_name" {
  description = "Name of the security group."
  type        = string
}

variable "security_group_description" {
  description = "Description of the security group."
  type        = string
}

variable "ingress_port" {
  description = "Inbound port that is allowed."
  type        = list(number)
}


variable "ingress_protocol" {
  description = "Inbound protocol, for example tcp."
  type        = string
}

variable "ingress_cidr_ipv4" {
  description = "IPv4 range allowed to connect inbound."
  type        = string
}

variable "egress_cidr_ipv4" {
  description = "IPv4 destination allowed outbound."
  type        = string
}

variable "egress_cidr_ipv6" {
  description = "IPv6 destination allowed outbound."
  type        = string
}

variable "egress_protocol" {
  description = "Outbound protocol (-1 means all)."
  type        = string
}

variable "igw_name" {
  description = "Name tag of the internet gateway."
  type        = string
}

variable "route_table_name" {
  description = "Name tag of the route table."
  type        = string
}

variable "public_route_cidr" {
  description = "Destination of the route that points to the internet gateway."
  type        = string
}
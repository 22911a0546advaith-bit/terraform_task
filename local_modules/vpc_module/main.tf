resource "aws_vpc" "test_vpc_terraform" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.test_vpc_terraform.id
  cidr_block              = var.subnet_cidr
  map_public_ip_on_launch = var.map_public_ip
}

resource "aws_security_group" "allow_tls" {
  name        = var.security_group_name
  description = var.security_group_description
  vpc_id      = aws_vpc.test_vpc_terraform.id

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  for_each = toset([for p in var.ingress_port : tostring(p)])
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.ingress_cidr_ipv4
  from_port         = tonumber(each.value)
  ip_protocol       = var.ingress_protocol
  to_port           = tonumber(each.value)
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.egress_cidr_ipv4
  ip_protocol       = var.egress_protocol
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv6         = var.egress_cidr_ipv6
  ip_protocol       = var.egress_protocol
}

resource "aws_internet_gateway" "test_gateway_for_test_vpc" {
  vpc_id = aws_vpc.test_vpc_terraform.id

  tags = {
    Name = var.igw_name
  }
}

resource "aws_route_table" "test_route_table" {
  vpc_id = aws_vpc.test_vpc_terraform.id

  route {
    cidr_block = var.public_route_cidr
    gateway_id = aws_internet_gateway.test_gateway_for_test_vpc.id
  }

  tags = {
    Name = var.route_table_name
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.test_route_table.id
}
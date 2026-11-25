output "subnet_id" {
  value = aws_subnet.example.id
}
output "securitygroup_id"{
    value = aws_security_group.allow_tls.id
}
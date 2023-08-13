output "vpc_id" {
  value = aws_vpc.main.id
}

output "az1" {
  value = local.az1
}

output "subnet_pub1" {
  value = aws_subnet.public1.id
}

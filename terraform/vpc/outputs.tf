output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_az1" {
  value = aws_subnet.public_az1.id
}

output "public_subnet_az2" {
  value = aws_subnet.public_az2.id
}

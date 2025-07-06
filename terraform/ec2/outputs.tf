output "jenkins_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip
}

output "jenkins_public_dns" {
  value = aws_instance.jenkins_ec2.public_dns
}

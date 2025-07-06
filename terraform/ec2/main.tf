# Create a key pair from your local public key file
resource "aws_key_pair" "this" {
  key_name   = "helm_jenkins_key"
  public_key = file("C:/Users/oluph/.ssh/helm_jenkins_key.pub")
}

# Security group for Jenkins EC2 instance
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow HTTP, SSH to Jenkins"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP for Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 instance to host Jenkins
resource "aws_instance" "jenkins_ec2" {
  ami                    = var.ami_id                # Example: Amazon Linux 2 AMI
  instance_type          = var.instance_type         # Example: t3.micro
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = var.subnet_id             # From your VPC module
  user_data              = file("${path.module}/user_data.sh")  # Script to install Jenkins & Helm

  tags = {
    Name = "JenkinsServer"
  }
}

#!/bin/bash
# Update the system
dnf update -y

# Install Java 17 (required for Jenkins)
dnf install -y java-17-amazon-corretto

# Install Git (for Jenkins pipeline)
dnf install -y git

# Add Jenkins repo and import key
wget https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.repo -O /etc/yum.repos.d/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# Install Jenkins
dnf install -y jenkins

# Enable and start Jenkins
systemctl enable jenkins
systemctl start jenkins

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Helm (latest)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Print versions for verification
java -version
docker --version
helm version

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
systemctl enable jenkins
systemctl start jenkins

# Install Docker
dnf install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user
usermod -aG docker jenkins

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

# Install aws-iam-authenticator
curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/latest/download/aws-iam-authenticator-linux-amd64
chmod +x aws-iam-authenticator
mv aws-iam-authenticator /usr/local/bin/

# Install Helm (latest)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# ✅ Install Nginx
amazon-linux-extras enable nginx1
dnf install -y nginx
systemctl enable nginx
systemctl start nginx

# Print versions for verification
java -version
docker --version
helm version
kubectl version --client
aws --version
aws-iam-authenticator help
nginx -v

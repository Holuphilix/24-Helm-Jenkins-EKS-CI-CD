# 🚀 Mini Project: Integrating Helm with CI/CD using Jenkins and EKS

## Introduction

This project demonstrates how to integrate Helm with Jenkins to build a continuous integration and continuous deployment (CI/CD) pipeline that automates application deployments to an Amazon EKS (Elastic Kubernetes Service) cluster. The Jenkins server runs on an EC2 instance provisioned with Terraform, and the pipeline deploys Helm charts to manage Kubernetes resources efficiently.

## Project Overview

The goal is to create an automated deployment pipeline where:

- Jenkins monitors a GitHub repository containing Helm charts.
- On each commit, Jenkins triggers a pipeline that deploys or updates the application on EKS using Helm commands.
- Infrastructure, including the Jenkins server on EC2, is provisioned via Terraform for repeatability and scalability.
- The Helm chart is customized to adjust application replicas and resource requests dynamically.

## Prerequisites

Before starting, ensure you have the following:

- An AWS account with permissions to create EC2, EKS, IAM roles, and other resources.
- Terraform installed and configured locally (`terraform` CLI and AWS CLI configured with `aws configure`).
- Access to an existing EKS cluster or willingness to provision one (optionally via Terraform).
- Helm CLI installed (on the Jenkins EC2 instance).
- Jenkins installed on an EC2 instance (provisioned via Terraform).
- Git installed locally for version control and pushing code.
- A Kubernetes context configured to allow Helm deployments to the target EKS cluster.
- Basic knowledge of Kubernetes, Helm, Terraform, and Jenkins pipelines.

## Tools and Technologies Used

| Tool/Technology       | Purpose                                                        |
|----------------------|----------------------------------------------------------------|
| **Terraform**         | Infrastructure provisioning (EC2, optionally EKS, IAM roles)  |
| **AWS EC2**           | Hosts the Jenkins server                                        |
| **Amazon EKS**        | Managed Kubernetes cluster for deploying the app               |
| **Jenkins**           | CI/CD automation server running on EC2                         |
| **Helm**              | Kubernetes package manager for deploying and managing releases |
| **Docker**            | Containerize the application (optional depending on app)       |
| **Git & GitHub**      | Source control and pipeline triggers                            |
| **kubectl**           | Kubernetes CLI for interacting with EKS                        |
| **IAM Roles**         | Secure AWS access between Jenkins and EKS                      |

## Project Structure

```bash
helm-jenkins-eks-cicd/
├── terraform/                      # All Terraform code lives here
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── user_data.sh
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── security_groups.tf      
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── provider.tf                 # Providers and backend config
│   ├── main.tf                     # Root Terraform file to reference other dirs
│   ├── variables.tf                # Shared root-level variables
│   ├── outputs.tf                  # Shared root-level outputs
│   └── terraform.tfvars            # Variable values
│
├── webapp/                         # Helm chart created via `helm create webapp`
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│
├── Dockerfile                      # Dockerize web app
├── Jenkinsfile                     # Jenkins CI/CD pipeline
├── .dockerignore
├── .gitignore
├── README.md                       # Project documentation
├── LICENSE                         # (Optional license file)
└── images/                         # Diagrams and screenshots
```

## **Task 1: Setup Project Folder and Directory** Structure

### Step 1: Create the Project Root Folder

Run this command in your desired workspace directory (e.g., `Documents/DevOps_WorkSpace_Projects/DAREY.IO_PROJECTS`):

```bash
mkdir helm-jenkins-eks-cicd
cd helm-jenkins-eks-cicd
```

**Screenshot:**
![Project Directory](/Images/1.mkdir_helm.png)

### Step 2: Create Project Subdirectories and Placeholder Files

Run this command inside the newly created project root folder to create Terraform folders, Helm chart folders, and key root files:

```bash
mkdir -p terraform/ec2
mkdir -p terraform/eks
mkdir -p terraform/vpc
mkdir -p terraform/iam
mkdir -p webapp/templates

touch terraform/provider.tf
touch terraform/terraform.tfvars

touch terraform/ec2/main.tf
touch terraform/ec2/variables.tf
touch terraform/ec2/outputs.tf
touch terraform/ec2/user_data.sh

touch terraform/vpc/main.tf
touch terraform/vpc/variables.tf
touch terraform/vpc/outputs.tf

touch terraform/iam/main.tf
touch terraform/iam/variables.tf
touch terraform/iam/outputs.tf

touch terraform/eks/main.tf
touch terraform/eks/variables.tf
touch terraform/eks/outputs.tf
touch terraform/eks/security_groups.tf

touch Jenkinsfile
touch Dockerfile
touch README.md
touch .gitignore
touch .dockerignore
```

## Task 2: Provision VPC, Subnet, Internet Gateway (Networking Foundation)

### Step 1: Create `terraform/vpc/main.tf`

```hcl
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

resource "aws_subnet" "public1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet-1"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-subnet-2"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.public.id
}
```


### Step 2: Create `terraform/vpc/variables.tf`

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "public_subnet_cidr_1" {
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  type        = string
  default     = "10.0.2.0/24"
}

variable "availability_zone_1" {
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  type        = string
  default     = "us-east-1b"
}
```

### Step 3: Create `terraform/vpc/outputs.tf`

```hcl
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_1_id" {
  value = aws_subnet.public1.id
}

output "public_subnet_2_id" {
  value = aws_subnet.public2.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public1.id, aws_subnet.public2.id]
}
```

### Step 4: Add VPC module call to root `main.tf`

```hcl
module "vpc" {
  source = "./vpc"

  vpc_cidr             = "10.0.0.0/16"
  vpc_name             = "main-vpc"
  public_subnet_cidr_1 = "10.0.1.0/24"
  public_subnet_cidr_2 = "10.0.2.0/24"
  availability_zone_1  = "us-east-1a"
  availability_zone_2  = "us-east-1b"
}
```

## Task 3: Provision EC2 for Jenkins with User Data to Install Jenkins & Helm

### Step 1: Create `terraform/ec2/main.tf`

```hcl
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
```

### Step 2: Create `terraform/ec2/variables.tf`

```hcl
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "SSH key pair name for EC2"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the EC2 instance"
  type        = string
}
```

### Step 3: Create `terraform/ec2/Output.tf`

```bash
output "jenkins_public_ip" {
  value = aws_instance.jenkins_ec2.public_ip
}

output "jenkins_public_dns" {
  value = aws_instance.jenkins_ec2.public_dns
}
```

### Step 4: Create `terraform/ec2/user_data.sh`

```bash
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
```

### Step 5: Update root `main.tf` to call EC2 module with outputs from VPC

```hcl
module "ec2_jenkins" {
  source         = "./ec2"
  ami_id         = "ami-05ffe3c48a9991133"
  instance_type  = "t3.medium"
  key_pair_name  = "helm_keypair"
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.public_subnet_1_id 
}
```

### Step 6: Terraform workflow

From your project root:

```bash
terraform init
terraform plan
terraform apply
```

- This will create the VPC, subnet, and then the EC2 instance configured with Jenkins and Helm installed.

## Task 4: Provision EKS Cluster Using Terraform

### 🎯 **Goal**: Provision an Amazon EKS cluster with required IAM roles, security groups, and networking using Terraform modules.

### ✅ Step 1: Create `terraform/eks/main.tf`

```hcl
resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

resource "aws_eks_node_group" "eks_nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = [var.node_instance_type]

  depends_on = [
    aws_eks_cluster.eks
  ]
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    mapRoles = jsonencode([
      {
        rolearn  = var.node_role_arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups   = ["system:bootstrappers", "system:nodes"]
      },
      {
        rolearn  = "arn:aws:iam::615299759133:role/Jenkin-eks-role"
        username = "jenkin-eks-role"
        groups   = ["system:masters"]
      }
    ])

    mapUsers = jsonencode([
      {
        userarn  = "arn:aws:iam::615299759133:user/jenkins-eks-user"
        username = "jenkins-eks-user"
        groups   = ["system:masters"]
      }
    ])
  }

  depends_on = [aws_eks_node_group.eks_nodes]
}
```

### ✅ Step 2: Create `terraform/eks/variables.tf`

```hcl
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster (optional)"
  type        = string
  default     = ""
}

variable "node_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_security_group_id" {
  description = "Security Group ID for EKS cluster"
  type        = string
}

variable "cluster_role_arn" {
  description = "ARN of the IAM role for EKS cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for EKS node group"
  type        = string
}
```

### ✅ Step 3: Create `terraform/eks/outputs.tf`

```hcl
output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  description = "The endpoint URL of the EKS cluster"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = var.eks_security_group_id
}

output "node_group_name" {
  description = "The name of the EKS node group"
  value       = aws_eks_node_group.eks_nodes.node_group_name
}


output "eks_security_group_id" {
  value = aws_security_group.eks_sg.id
}
```

### ✅ Step 4: Create `terraform/eks/security_groups.tf`

```hcl
resource "aws_security_group" "eks_sg" {
  name        = "eks-cluster-sg"
  description = "Security group for EKS cluster communication"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"] # Update based on your VPC CIDR
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### ✅ Step 5: Update `terraform/main.tf` (root)

```hcl
module "eks" {
  source                = "./eks"
  cluster_name          = "helm-eks-cluster"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids  # 👈 Should be a list of two subnets
  node_instance_type    = "t3.medium"
  eks_security_group_id = module.eks.eks_security_group_id  # Optional if security group created in same module

  cluster_role_arn      = module.iam.eks_cluster_role_arn
  node_role_arn         = module.iam.eks_node_role_arn
}
```

### ✅ Step 6: Run Terraform

```bash
cd terraform
terraform init
terraform plan -out eks-plan
terraform apply eks-plan
```

## 📘**Task 5: IAM Role Module for Jenkins EC2**

This task focuses on creating a modular and reusable **IAM Role configuration** using Terraform. The role is designed specifically for a **Jenkins EC2 instance** that will interact with AWS services like EKS.

### 📁 Folder Structure

The IAM configuration is structured within its own folder under the `terraform/` directory for clarity and modularity. It includes:

* `main.tf`: Defines the IAM role, policies, and instance profile.
* `variables.tf`: Manages input variables (e.g., role name).
* `outputs.tf`: Exposes outputs for use in other modules or root configuration.

### 🛠️ Functionality

* Grants the EC2 instance permissions for:

  * Managing EKS clusters and worker nodes.
  * Accessing Amazon ECR for container images.
  * Using AWS Systems Manager (SSM) for remote access.
* Attaches the IAM role to an instance profile for EC2 use.


### ✅ Folder Structure

```
terraform/
├── iam/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── main.tf
├── variables.tf
└── outputs.tf
```

### ✅ `terraform/iam/main.tf`

```hcl
# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Role
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

# Jenkins EC2 Role
resource "aws_iam_role" "jenkins_role" {
  name = var.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "jenkins_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "jenkins_ECRFullAccess" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "jenkins_SSM" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.jenkins_role.name
}
```

### ✅ `terraform/iam/variables.tf`

```hcl
variable "role_name" {
  description = "Base name for the Jenkins IAM role"
  type        = string
  default     = "jenkins-iam-role"
}
```

### ✅ `terraform/iam/outputs.tf`

```hcl
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster_role.arn
}

output "eks_node_role_arn" {
  description = "ARN of the EKS node IAM role"
  value       = aws_iam_role.eks_node_role.arn
}

output "jenkins_role_arn" {
  description = "ARN of the Jenkins EC2 IAM role"
  value       = aws_iam_role.jenkins_role.arn
}

output "jenkins_instance_profile" {
  description = "Instance profile name for Jenkins EC2 role"
  value       = aws_iam_instance_profile.jenkins_profile.name
}
```

### ✅ Usage

The module is called from the root `main.tf` using:

```hcl
module "iam" {
  source    = "./iam"
  role_name = "jenkins-eks-role"
}
```

**After configuring, simply run:**

```bash
cd terraform
terraform init
terraform apply
```

## 🔧 **Task 6: Connect kubectl to EKS Cluster and Verify Access**

### 🎯 Objective

* Update your local `kubeconfig` to point to your new EKS cluster.
* Test access with `kubectl` to ensure it's properly connected.

### ✅ **Step 1: Install & Configure `kubectl`**

- Installation of `kubectl` :

```bash
curl.exe -LO https://dl.k8s.io/release/v1.30.1/bin/windows/amd64/kubectl.exe
```

Or follow the [official guide](https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/) if on Windows.

**Screenshot**
![install Kubernetes](./Images/3.download_kubernetes.png)

### ✅ **Step 2: Update kubeconfig using AWS CLI**

```bash
aws eks --region us-east-1 update-kubeconfig --name helm-eks-cluster
```

**Screenshot**
![Update kubeconfig](./Images/4.update_kubeconfig.png)

This command sets the context to interact with your cluster via `kubectl`.

### ✅ **Step 3: Verify Cluster Connection**

```bash
kubectl get nodes
```

**Screenshot Expected Output:**
![Verify clsuter connection](./Images/5.kubectl_nodes.png)
If you see the worker nodes, your connection is successful.

### ✅ Step 4: View Cluster Info

```bash
kubectl cluster-info
```
![cluster info](./Images/6.cluster_info.png)

## Task 7: Automate Helm Deployment with Jenkins Pipeline (CI/CD)

### 🎯 **Goal:**

Set up a Jenkins pipeline that automatically builds a Docker image, pushes it to Docker Hub, and deploys the app to Amazon EKS using Helm whenever changes are pushed to GitHub.

### 🛠️ Prerequisites

* Jenkins is running on your EC2 instance
* Docker is installed and Jenkins has permission to use it
* Helm is installed and configured
* Jenkins has access to your GitHub repo
* **Docker Hub credentials and AWS credentials are added in Jenkins (see below)**
* Your EKS cluster is working and `aws eks update-kubeconfig` has been run successfully on the Jenkins host or configured in the pipeline

### 📝 Step 1: Add AWS Credentials to Jenkins

1. Navigate to **Manage Jenkins > Credentials > (your domain)**.
2. Click **Add Credentials**.
3. Select **Username with password**.
4. For **Username**, enter your AWS Access Key ID.
5. For **Password**, enter your AWS Secret Access Key.
6. Set **ID** to `aws-cred` (or the same ID referenced in your Jenkinsfile).
7. Click **OK** to save.

**This credential will be used by Jenkins to authenticate AWS CLI commands for EKS operations.**

### Step 2: How to Add Docker Hub Credentials in Jenkins

1. **Open Jenkins Dashboard**
   Log into your Jenkins web UI.

2. **Navigate to Manage Credentials**

   * Click on **Manage Jenkins** (usually on the left menu or from the dashboard).
   * Then click **Manage Credentials**.

3. **Choose a Credentials Domain**

   * Usually, you'll see one or more domains (e.g., `(global)` domain).
   * Click on `(global)` or the domain where you want to add credentials.

4. **Add Credentials**

   * Click **Add Credentials** (usually on the left sidebar or the main pane).

5. **Fill in the Credentials Details:**

   * **Kind:** Select **Username with password**
   * **Scope:** Choose **Global** (so it can be used anywhere in Jenkins)
   * **Username:** Your Docker Hub username (e.g., `your-docker-username`)
   * **Password:** Your Docker Hub password or better, a Docker Hub access token (recommended for security)
   * **ID:** `docker-cred` (This ID should match what you reference in your Jenkinsfile or pipeline script)
   * **Description:** Something like `"Docker Hub credentials"`

6. **Save**
   Click **OK** or **Save** to finish adding the credentials.

### Notes:

* It's recommended to use a **Docker Hub access token** (created from your Docker Hub account settings) instead of your actual password for better security.
* The **ID** is important because your Jenkins pipeline or freestyle job will refer to this credential ID to authenticate against Docker Hub.


### 📄 Step 3: Update Your Helm Chart

#### 1️⃣ Edit `webapp/values.yaml`

```yaml
replicaCount: 3
```

#### 2️⃣ Edit `webapp/templates/deployment.yaml`

Update resource requests:

```yaml
resources:
  requests:
    memory: "180Mi"
    cpu: "120m"
```

### 🐳 Step 4: Create a Dockerfile

```Dockerfile
# Use Nginx as the base image
FROM nginx:stable

# Copy your web app files into the Nginx HTML directory
COPY . /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
```

Also create a `.dockerignore`:

```
*.tar
*.zip
*.log
node_modules
.vscode
.git
*.lz4
```

### 📝 Step 5: Jenkinsfile for CI/CD

#### 1: Configure Automatic Build Trigger

Set Jenkins to automatically detect new commits in Git repository:

+ GitHub Webhook :

    Go to your GitHub repository settings.

    Navigate to Webhooks → Add webhook.

    Enter the URL for your Jenkins Git plugin:

http://98.81.101.128:8080/github-webhook/

    Select Push events.

    Save the webhook.

    Jenkins will now trigger builds when you push code to your GitHub repository.

#### 2: GitHub Credentials:

    In Jenkins, go to Manage Jenkins → Credentials.

    Add your GitHub username/password or token.

#### 3: Configure Jenkins Job
**Create a New Pipeline:**
1. In Jenkins dashboard, click **New Item > Pipeline**.
2. Name it `helm-webapp-deploy`.
3. Choose **Pipeline script from SCM**.
4. Choose **Git** and paste your GitHub repo URL.
5. Select the `main` branch.
6. Choose credentials if the repo is private.
7. Click **Save**.

![Jenkins New Pipeline](./Images/8.jenkins_new_name.png)

#### 4: Set Up Pipeline:
     **Create a Jenkinsfile:**

```groovy
pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        DOCKERHUB_IMAGE = 'holuphilix/my-webapp:latest'
    }

    triggers {
        githubPush()
    }

    stages {
        stage('Build and Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USERNAME',
                    passwordVariable: 'DOCKER_PASSWORD'
                )]) {
                    sh '''
                        echo "🔐 Logging in to Docker Hub..."
                        echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin

                        echo "🔧 Building Docker image..."
                        docker build -t $DOCKERHUB_IMAGE .

                        echo "📤 Pushing image to Docker Hub..."
                        docker push $DOCKERHUB_IMAGE

                        echo "🧹 Cleaning up local image..."
                        docker rmi $DOCKERHUB_IMAGE || true
                    '''
                }
            }
        }

        stage('Deploy with Helm') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'aws-cred',
                    usernameVariable: 'AWS_ACCESS_KEY_ID',
                    passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                )]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                        echo "⚙️ Configuring access to EKS..."
                        aws eks --region ${AWS_DEFAULT_REGION} update-kubeconfig --name my-eks-cluster

                        echo "🚀 Deploying to EKS with Helm..."
                        helm upgrade --install my-webapp ./webapp --namespace default
                    '''
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment succeeded!'
        }
        failure {
            echo '❌ Deployment failed. Please check logs above.'
        }
    }
}
```

### Step 6: Jenkins login portal

```bash
http://98.81.101.128:8080
```

![Jenkins Portal](./Images/11.jenkins_login.png)

### Step 7: Test a deployment (e.g., NGINX):

```bash
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```
![create deployment nginx](./Images/9.test_ngnix.png)

### Step 8: kubectl get pods on Ec2 Instance

```bash
kubectl get pods
```
**Screenshot:** Test on Ec2 Instance 

![Kubectl get pods](./Images/12.Ec2_kubectl_pods.png)

## Task 8: Trigger CI/CD Pipeline and Verify End-to-End Deployment

Push a commit to GitHub to trigger the Jenkins CI/CD pipeline. Confirm that the pipeline builds the Docker image, deploys the Helm chart to the EKS cluster, and successfully exposes the application via a LoadBalancer. Finally, test the deployed Nginx web app in the browser and clean up the infrastructure afterward.

### Step 1: Push a commit to your GitHub repo to trigger the pipeline

```bash
git init
git add .
git commit -m "Connect Jenkins pipeline with Helm and Docker"
git remote add origin https://github.com/Holuphilix/helm-jenkins-eks-cicd.git
git branch -M main
git push -u origin main
```

### Step 2: Verify deployment with:

```bash
kubectl get pods -n default
kubectl get svc -n default
helm list
```
![Helm list](./Images/14.helm_list.png)

### Step 3: Verify Build On Jenkins:

- **Display of jenkins pipeline after build:**

![jenkins build](./Images/13.jenkins_build.png)

### Step 4: Verify Deployed Application:

```bash
kubectl get svc
```
![Test Deployed Application](./Images/15.kubectl_svc_nginx.png)

###  Step 5: Test nginx App On Browser:

Open your browser and navigate to:

```bash
http://a89d4f75272d040aea78b98abc86ca42-356428106.us-east-1.elb.amazonaws.com
```
![Nginx Application](./Images/18.ngnix_website.png)

### 🧹 Step 6: Clean Up Resources 

```bash
terraform destroy
```

## Conclusion
This project showcases the seamless integration of Terraform, Jenkins, and Helm to implement a modern, automated CI/CD pipeline. By provisioning cloud infrastructure using Terraform, configuring Jenkins to trigger builds on code changes, and deploying updated Helm charts to an EKS cluster, we demonstrated a full DevOps workflow from infrastructure-as-code to application deployment. The project emphasizes reproducibility, scalability, and automation — key pillars of DevOps best practices — and provides a strong foundation for real-world continuous delivery pipelines.

## Author
**Philip Oluwaseyi Oludolamu**

DevOps Engineer 

* ✉️ Email: [oluphilix@gmail.com](mailto:oluphilix@gmail.com)
* 🔗 LinkedIn: [linkedin.com/in/philipoludolamu](https://www.linkedin.com/in/philipoludolamu)

*Completed on July 14, 2025*

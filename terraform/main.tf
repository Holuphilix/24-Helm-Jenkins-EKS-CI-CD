module "vpc" {
  source = "./vpc"

  vpc_cidr             = "10.0.0.0/16"
  vpc_name             = "main-vpc"
  public_subnet_cidr_1 = "10.0.1.0/24"
  public_subnet_cidr_2 = "10.0.2.0/24"
  availability_zone_1  = "us-east-1a"
  availability_zone_2  = "us-east-1b"
}

module "iam" {
  source    = "./iam"
  role_name = "jenkins-eks-role"
}

module "ec2_jenkins" {
  source         = "./ec2"
  ami_id         = "ami-05ffe3c48a9991133"
  instance_type  = "t3.medium"
  key_pair_name  = "helm_keypair"
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.public_subnet_1_id  # 👈 Make sure this output exists in vpc/outputs.tf
}

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

module "vpc" {
  source                  = "./vpc"
  vpc_cidr                = "10.0.0.0/16"
  vpc_name                = "main-vpc"
  public_subnet_az1_cidr  = "10.0.1.0/24"
  public_subnet_az2_cidr  = "10.0.2.0/24"
}

module "ec2_jenkins" {
  source         = "./ec2"
  ami_id         = "ami-05ffe3c48a9991133"
  instance_type  = "t3.micro"
  key_pair_name  = "helm_keypair"
  vpc_id         = module.vpc.vpc_id
  subnet_id      = module.vpc.public_subnet_az1
}

module "eks" {
  source            = "./eks"
  cluster_name      = "helm-eks-cluster"
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = [
    module.vpc.public_subnet_az1,
    module.vpc.public_subnet_az2
  ]
  node_instance_type = "t3.medium"
}

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



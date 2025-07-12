# outputs.tf
# This file defines the output values from the EKS cluster setup.

output "cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster."
  value       = module.eks_cluster.cluster_endpoint
}

output "kubeconfig_command" {
  description = "Command to update your kubeconfig to connect to the EKS cluster."
  value       = "aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region}"
}

output "vpc_id" {
  description = "The ID of the VPC created."
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of public subnets."
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of private subnets."
  value       = module.vpc.private_subnets
}
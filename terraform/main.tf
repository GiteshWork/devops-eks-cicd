# main.tf
# This file defines the core AWS resources for the EKS cluster and its networking.
# It uses the terraform-aws-modules for VPC and EKS for simplified deployment.

# 1. VPC Module: Create a new VPC for the EKS cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = {
    Environment = "DevOpsAssignment"
    Project     = var.cluster_name
  }
}

# 2. EKS Cluster IAM Role: Create a dedicated IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Environment = "DevOpsAssignment"
    Project     = var.cluster_name
  }
}

# Attach the AmazonEKSClusterPolicy to the EKS cluster IAM role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# 3. EKS Cluster Module: Deploy the EKS Cluster
module "eks_cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true
  # REMOVED: 'public_access_cidrs' is not a direct argument for this module version.

  # REMOVED: 'cluster_iam_role_arn' is not a direct argument for this module version.

  tags = {
    Environment = "DevOpsAssignment"
    Project     = var.cluster_name
  }
}

# 4. EKS Managed Node Group: Create a dedicated node group for worker nodes
module "eks_managed_node_group" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.0"

  cluster_name    = module.eks_cluster.cluster_name
  cluster_version = module.eks_cluster.cluster_version

  name = "${var.cluster_name}-ng" # Shortened name to fit AWS character limits

  desired_size = var.desired_capacity
  max_size     = var.max_capacity
  min_size     = var.min_capacity

  instance_types = [var.instance_type]
  subnet_ids     = module.vpc.private_subnets
  ami_type       = "AL2_x86_64"
  disk_size      = 20

  create_iam_role = true
  iam_role_name   = "${var.cluster_name}-node-group-role"

  tags = {
    Environment = "DevOpsAssignment"
    Project     = var.cluster_name
  }
}
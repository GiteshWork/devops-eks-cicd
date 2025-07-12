# variables.tf
# This file defines the input variables for the EKS cluster setup.

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1" # As you are in India, this is a common region.
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "my-devops-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.28" # Or your desired EKS version
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium" # Adjust based on your workload and budget
}

variable "desired_capacity" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 3
}

variable "min_capacity" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}
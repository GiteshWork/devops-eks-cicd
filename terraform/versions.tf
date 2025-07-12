# versions.tf
# This file defines the required Terraform and provider versions.

terraform {
  required_version = ">= 1.0.0" # Specifies the minimum Terraform CLI version required 

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Pinning to AWS provider v5.x.x for compatibility with EKS module v19.x 
    }
    # These providers are implicitly required by the EKS module dependencies.
    # Explicitly including them here for clarity and to prevent unexpected errors.
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0" # A common compatible version for Kubernetes provider with EKS.
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0.0"
    }
  }
}

# Configure the AWS provider with the region defined in variables.tf
provider "aws" {
  region = var.aws_region
}
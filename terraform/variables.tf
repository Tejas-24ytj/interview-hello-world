# ============================================
# General Variables
# ============================================

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "hello-world"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# ============================================
# Networking Variables
# ============================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway for cost savings"
  type        = bool
  default     = true
}

# ============================================
# ECR Variables
# ============================================

variable "ecr_image_count" {
  description = "Number of images to keep in ECR"
  type        = number
  default     = 10
}

# ============================================
# EKS Variables
# ============================================

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.33"
}

variable "instance_types" {
  description = "Instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Type of capacity (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "disk_size" {
  description = "Disk size in GB for worker nodes"
  type        = number
  default     = 20
}

# ============================================
# IAM Variables
# ============================================

variable "github_repository_pattern" {
  description = "GitHub repository pattern for OIDC (e.g., repo:username/repo:*)"
  type        = string
  default     = "repo:*:*"
}

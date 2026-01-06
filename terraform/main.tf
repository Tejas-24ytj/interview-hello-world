# Main Terraform Configuration
# This file orchestrates all modules to create the complete infrastructure

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
  
  # Exclude us-east-1e as EKS doesn't support it
  exclude_names = ["us-east-1e"]
}

# Local variables
locals {
  cluster_name = "${var.project_name}-${var.environment}"
  
  # Use only first 3 AZs that EKS supports
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "Tejas23"
  }
}

# ============================================
# Networking Module
# ============================================
module "networking" {
  source = "./modules/networking"

  vpc_name           = "${var.project_name}-${var.environment}-vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = local.azs
  cluster_name       = local.cluster_name
  single_nat_gateway = var.single_nat_gateway

  tags = local.common_tags
}

# ============================================
# ECR Module
# ============================================
module "ecr" {
  source = "./modules/ecr"

  repository_name = local.cluster_name
  image_count     = var.ecr_image_count

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ecr"
    }
  )
}

# ============================================
# EKS Module
# ============================================
module "eks" {
  source = "./modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version
  
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.private_subnets

  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  
  min_size     = var.min_size
  max_size     = var.max_size
  desired_size = var.desired_size
  disk_size    = var.disk_size

  node_labels = {
    Environment = var.environment
    NodeGroup   = "default"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-eks"
    }
  )
}

# ============================================
# IAM Module
# ============================================
module "iam" {
  source = "./modules/iam"

  project_name              = "${var.project_name}-${var.environment}"
  eks_oidc_issuer_url       = module.eks.cluster_oidc_issuer_url
  github_repository_pattern = var.github_repository_pattern

  tags = local.common_tags

  depends_on = [module.eks]
}


# EKS Cluster Module
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  # Cluster endpoint access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # VPC and Subnet Configuration
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Cluster Add-ons
  cluster_addons = var.cluster_addons

  # EKS Managed Node Group
  eks_managed_node_groups = {
    default = {
      name = "nodes"  # Short name to avoid IAM role name length issues

      instance_types = var.instance_types
      capacity_type  = var.capacity_type

      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      disk_size = var.disk_size

      labels = var.node_labels

      tags = var.tags
      
      # Disable name prefix for IAM role to avoid length issues
      iam_role_use_name_prefix = false
    }
  }

  # aws-auth ConfigMap
  manage_aws_auth_configmap = true

  tags = var.tags
}

# Security group rule to allow worker nodes to pull from ECR
resource "aws_security_group_rule" "node_to_ecr" {
  description       = "Allow nodes to pull images from ECR"
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.node_security_group_id
}


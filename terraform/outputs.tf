# ============================================
# Networking Outputs
# ============================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "private_subnets" {
  description = "List of private subnet IDs"
  value       = module.networking.private_subnets
}

output "public_subnets" {
  description = "List of public subnet IDs"
  value       = module.networking.public_subnets
}

# ============================================
# ECR Outputs
# ============================================

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = module.ecr.repository_name
}

output "ecr_repository_arn" {
  description = "ECR repository ARN"
  value       = module.ecr.repository_arn
}

# ============================================
# EKS Outputs
# ============================================

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "eks_cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.eks.cluster_oidc_issuer_url
}

# ============================================
# IAM Outputs
# ============================================

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions (Add this to GitHub Secrets)"
  value       = module.iam.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "IAM Role name for GitHub Actions"
  value       = module.iam.github_actions_role_name
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = module.iam.aws_account_id
}

# ============================================
# Helpful Commands
# ============================================

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "instructions" {
  description = "Next steps after Terraform apply"
  value       = <<-EOT
  
  ✅ Infrastructure Created Successfully!
  
  Next Steps:
  1. Configure kubectl:
     aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}
  
  2. Add this to GitHub Secrets:
     Secret Name: AWS_ROLE_ARN
     Secret Value: ${module.iam.github_actions_role_arn}
  
  3. Update terraform/terraform.tfvars with your GitHub repository:
     github_repository_pattern = "repo:YOUR_USERNAME/interview-hello-world:*"
     Then run: terraform apply
  
  4. Push code to GitHub to trigger CI/CD pipeline
  
  5. Get LoadBalancer URL after deployment:
     kubectl get svc hello-world -n default
  
  EOT
}

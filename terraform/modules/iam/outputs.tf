output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "IAM Role name for GitHub Actions"
  value       = aws_iam_role.github_actions.name
}

output "github_oidc_provider_arn" {
  description = "ARN of GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "eks_oidc_provider_arn" {
  description = "ARN of EKS OIDC provider"
  value       = data.aws_iam_openid_connect_provider.eks.arn
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}


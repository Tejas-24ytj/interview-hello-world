variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "eks_oidc_issuer_url" {
  description = "OIDC issuer URL from EKS cluster"
  type        = string
}

variable "github_repository_pattern" {
  description = "GitHub repository pattern for OIDC trust (e.g., repo:username/repo:*)"
  type        = string
  default     = "repo:*:*"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}


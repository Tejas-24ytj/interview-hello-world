# Terraform Infrastructure

This directory contains the Terraform configuration for provisioning AWS infrastructure including VPC, EKS, ECR, and IAM resources.

## Directory Structure

```
terraform/
├── main.tf                    # Main configuration orchestrating all modules
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── providers.tf               # Provider configuration
├── terraform.tfvars.example   # Example variables file
├── .gitignore                 # Git ignore rules
├── modules/                   # Reusable modules
│   ├── networking/            # VPC, subnets, NAT gateway
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ecr/                   # Container registry
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── eks/                   # Kubernetes cluster
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── iam/                   # OIDC providers and IAM roles
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── README.md                  # This file
```

## Architecture

The infrastructure consists of:

### Networking Module
- VPC with public and private subnets across 3 AZs
- NAT Gateway for outbound internet access
- Internet Gateway for public subnets
- Route tables and security groups

### ECR Module
- Private container registry
- Image scanning on push
- Lifecycle policy (keeps last 10 images)
- Encryption at rest

### EKS Module
- Managed Kubernetes cluster (v1.33)
- Managed node group (2 t3.medium instances)
- CoreDNS, kube-proxy, and VPC CNI add-ons
- Auto-scaling capabilities

### IAM Module
- GitHub OIDC provider for secure authentication
- EKS OIDC provider for service accounts
- IAM role for GitHub Actions with minimal permissions

## Quick Start

### Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- kubectl >= 1.28

### Step 1: Initialize

```bash
cd terraform
terraform init
```

### Step 2: Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (optional)
```

### Step 3: Plan

```bash
terraform plan
```

### Step 4: Apply

```bash
terraform apply
# Type 'yes' when prompted
```

### Step 5: Save Outputs

```bash
# View all outputs
terraform output

# Save GitHub Actions role ARN (needed for GitHub secrets)
terraform output -raw github_actions_role_arn
```

## Configuration

### Required Variables

None - all variables have defaults.

### Optional Variables

You can customize these in `terraform.tfvars`:

```hcl
# General
aws_region   = "us-east-1"
project_name = "hello-world"
environment  = "dev"

# Networking
vpc_cidr           = "10.0.0.0/16"
single_nat_gateway = true

# ECR
ecr_image_count = 10

# EKS
cluster_version = "1.33"
instance_types  = ["t3.medium"]
capacity_type   = "ON_DEMAND"
desired_size    = 2
min_size        = 1
max_size        = 3
disk_size       = 20

# GitHub OIDC
github_repository_pattern = "repo:YOUR_USERNAME/interview-hello-world:*"
```

### Important: Update GitHub Repository Pattern

After forking the repository, update `github_repository_pattern`:

```hcl
github_repository_pattern = "repo:tejasl/interview-hello-world:*"
```

Then re-apply:
```bash
terraform apply
```

## Outputs

Key outputs you'll need:

| Output | Description | Usage |
|--------|-------------|-------|
| `github_actions_role_arn` | IAM role ARN | Add to GitHub secrets as `AWS_ROLE_ARN` |
| `eks_cluster_name` | EKS cluster name | Used in GitHub Actions workflows |
| `ecr_repository_url` | ECR repository URL | Where Docker images are pushed |
| `configure_kubectl` | kubectl config command | Run to access your cluster |

## Useful Commands

### View Infrastructure State

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show module.eks.module.eks.aws_eks_cluster.this[0]

# View outputs
terraform output
```

### Update Infrastructure

```bash
# After changing variables or code
terraform plan
terraform apply
```

### Destroy Infrastructure

```bash
# Delete Kubernetes resources first
kubectl delete -f ../k8s/

# Then destroy Terraform resources
terraform destroy
```

## Troubleshooting

### Issue: Terraform init fails

**Solution**: Check internet connectivity and AWS credentials:
```bash
aws sts get-caller-identity
```

### Issue: Apply fails with "UnauthorizedOperation"

**Solution**: Ensure your AWS credentials have sufficient permissions (AdministratorAccess or equivalent).

### Issue: EKS creation times out

**Solution**: This is normal - EKS takes 15-20 minutes. Wait patiently.

### Issue: Module not found

**Solution**: Ensure you're in the terraform directory:
```bash
cd terraform
terraform init
```

## Resource Naming Convention

Resources are named using the pattern: `{project_name}-{environment}-{resource_type}`

Examples:
- VPC: `hello-world-dev-vpc`
- EKS: `hello-world-dev`
- ECR: `hello-world-dev`

 **Implemented:**
- VPC with private subnets for EKS nodes
- Security groups with minimal required access
- IAM roles with least privilege principle
- OIDC instead of long-lived credentials
- Encrypted ECR repository
- Image vulnerability scanning

## Module Documentation

### Networking Module

Creates a VPC with:
- 3 availability zones
- Public subnets for load balancers
- Private subnets for EKS nodes
- NAT gateway for outbound connectivity

### ECR Module

Creates a container registry with:
- Private repository
- Image scanning enabled
- Lifecycle policy to manage image retention
- Encryption at rest

### EKS Module

Creates a Kubernetes cluster with:
- Managed control plane
- Managed node group with auto-scaling
- CoreDNS, kube-proxy, VPC CNI add-ons
- Integration with VPC private subnets

### IAM Module

Creates IAM resources for:
- GitHub Actions OIDC authentication
- EKS service account integration
- Minimal required permissions

## State Management

### Local State (Default)

State is stored locally in `terraform.tfstate` file.

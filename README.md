# Hello World - EKS Deployment with CI/CD

A production-ready Node.js Express application deployed on AWS EKS with automated CI/CD pipelines using GitHub Actions, Infrastructure as Code using Terraform, and security scanning with Trivy.

##  Architecture Overview

This project demonstrates a complete DevOps workflow:

- **Infrastructure**: AWS EKS cluster with VPC, ECR repository provisioned via Terraform
- **CI Pipeline**: Automated linting, building, security scanning, and pushing to ECR
- **CD Pipeline**: Automated deployment to EKS using OIDC authentication (no long-lived credentials)
- **Security**: Trivy vulnerability scanning, non-root containers, OIDC-based authentication
- **Kubernetes**: LoadBalancer service, health checks, resource limits, rolling updates

## Prerequisites

Before you begin, ensure you have the following installed:

- [AWS CLI](https://aws.amazon.com/cli/) (v2.x or later)
- [Terraform](https://www.terraform.io/downloads.html) (v1.0 or later)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) (v1.33 or later)
- [Docker](https://docs.docker.com/get-docker/) (for local testing)
- [Node.js](https://nodejs.org/) (v18 or later)
- AWS Account with appropriate permissions
- GitHub Account

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/interview-hello-world.git
cd interview-hello-world
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and output format
```

### 3. Deploy Infrastructure with Terraform

#### Step 1: Initialize Terraform

```bash
cd terraform
terraform init
```

#### Step 2: Review and Customize Variables (Optional)

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your preferred values
```

Default values:
- **AWS Region**: us-east-1
- **Project Name**: hello-world
- **Environment**: dev
- **EKS Version**: 1.33
- **Instance Type**: t3.medium
- **Node Count**: 2 (min: 1, max: 3)

#### Step 3: Plan Infrastructure Changes

```bash
terraform plan
```

#### Step 4: Apply Infrastructure

```bash
terraform apply
# Type 'yes' when prompted
```

#### Step 5: Save Important Outputs

After successful deployment, save these outputs:

```bash
# Get all outputs
terraform output

# Save specific outputs for GitHub secrets
terraform output -raw github_actions_role_arn
terraform output -raw ecr_repository_url
terraform output -raw eks_cluster_name
```

### 4. Configure kubectl

```bash
aws eks update-kubeconfig --region us-east-1 --name hello-world-dev

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### 5. Setup GitHub Actions (CI/CD)

#### Step 1: Fork this Repository

Fork this repository to your GitHub account.

#### Step 2: Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secret:

| Secret Name | Value | Description |
|------------|-------|-------------|
| `AWS_ROLE_ARN` | `arn:aws:iam::ACCOUNT_ID:role/hello-world-dev-github-actions` | IAM Role ARN from Terraform output |

To get the Role ARN:
```bash
cd terraform
terraform output github_actions_role_arn
```

#### Step 3: Update Workflow Variables (if needed)

If you changed the default Terraform variables, update these files:

- `.github/workflows/ci.yaml`
- `.github/workflows/cd.yaml`

Update the following environment variables to match your configuration:
```yaml
env:
  AWS_REGION: us-east-1          # Your AWS region
  ECR_REPOSITORY: hello-world-dev # Your ECR repository name
  EKS_CLUSTER_NAME: hello-world-dev # Your EKS cluster name
```

#### Step 4: Configure GitHub OIDC Provider Trust

Update the GitHub Actions IAM role trust policy to allow your specific repository:

```bash
# Get your GitHub username/organization
GITHUB_REPO="your-username/interview-hello-world"

# Update the trust policy
cd terraform
```

Edit `terraform/iam-oidc.tf` and update line 25:

```hcl
"token.actions.githubusercontent.com:sub" : "repo:YOUR_GITHUB_USERNAME/interview-hello-world:*"
```

Then apply the changes:

```bash
terraform apply
```

### 6. Trigger CI/CD Pipeline

#### Option 1: Push to Main Branch

```bash
git add .
git commit -m "Initial deployment setup"
git push origin main
```

#### Option 2: Create a Pull Request

The CI pipeline will run on pull requests for validation without deploying.

### 7. Monitor Pipeline Execution

1. Go to your GitHub repository
2. Click on **Actions** tab
3. Watch the **CI Pipeline** workflow
4. After CI completes, the **CD Pipeline** will automatically trigger
5. Wait for both pipelines to complete successfully

### 8. Access Your Application

After successful deployment, get the LoadBalancer URL:

```bash
kubectl get svc hello-world -n default

# Or wait for the external hostname
kubectl get svc hello-world -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Access your application:
```bash
# Get the URL
LOAD_BALANCER_URL=$(kubectl get svc hello-world -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://${LOAD_BALANCER_URL}"

# Test the application
curl http://${LOAD_BALANCER_URL}
curl http://${LOAD_BALANCER_URL}/health
```

## Pipeline Details

### CI Pipeline (Continuous Integration)

Triggers on: Push to `main` branch or Pull Request

**Jobs:**

1. **Lint** 
   - Checks code quality using ESLint
   - Fails if there are linting errors

2. **Build and Security Scan**
   - Builds Docker image
   - Scans for vulnerabilities using Trivy
   - Fails on HIGH or CRITICAL vulnerabilities
   - Saves image as artifact

3. **Push to ECR** (only on main branch)
   - Authenticates using OIDC (no long-lived credentials)
   - Tags image with git SHA and timestamp
   - Pushes to Amazon ECR
   - Also tags as `latest`

### CD Pipeline (Continuous Deployment)

Triggers on: Successful completion of CI Pipeline

**Jobs:**

1. **Deploy to EKS**
   - Authenticates using OIDC
   - Configures kubectl for EKS
   - Updates Kubernetes deployment with new image
   - Applies all manifests
   - Waits for rollout completion
   - Displays LoadBalancer URL

## Infrastructure Components

### AWS Resources Created by Terraform

1. **VPC and Networking**
   - VPC with public and private subnets across 3 AZs
   - Internet Gateway
   - NAT Gateway (single for cost optimization)
   - Route tables

2. **EKS Cluster**
   - EKS control plane (v1.28)
   - Managed node group (2 t3.medium instances)
   - Required add-ons (CoreDNS, kube-proxy, VPC CNI)

3. **ECR Repository**
   - Private Docker registry
   - Image scanning enabled
   - Lifecycle policy (keeps last 10 images)

4. **IAM & OIDC**
   - OIDC provider for EKS
   - OIDC provider for GitHub Actions
   - IAM role for GitHub Actions with ECR and EKS permissions

### Kubernetes Resources

1. **Deployment**
   - 2 replicas for high availability
   - Resource limits (256Mi memory, 200m CPU)
   - Liveness and readiness probes
   - Rolling update strategy
   - Non-root user for security

2. **Service**
   - Type: LoadBalancer
   - External access on port 80
   - Routes to container port 3000

## Security Features

### Infrastructure Security

- ✅ Private ECR repository with encryption
- ✅ EKS cluster in private subnets
- ✅ OIDC-based authentication (no long-lived AWS keys)
- ✅ IAM roles with least privilege
- ✅ Security groups with minimal required access
- ✅ Encrypted EBS volumes for worker nodes

### Container Security

- ✅ Multi-stage Docker build
- ✅ Non-root user in container
- ✅ Minimal base image (node:18-alpine)
- ✅ Vulnerability scanning with Trivy
- ✅ Only production dependencies

### Application Security

- ✅ Health check endpoints
- ✅ Graceful shutdown handling
- ✅ No sensitive data in logs
- ✅ Resource limits to prevent DoS

## Local Development

### Run Locally

```bash
# Install dependencies
npm install

# Run the application
npm start

# Access the application
curl http://localhost:3000
curl http://localhost:3000/health
```

### Build and Test Docker Image Locally

```bash
# Build Docker image
docker build -t hello-world:local .

# Run container
docker run -p 3000:3000 hello-world:local

# Test
curl http://localhost:3000
```

### Run Security Scan Locally

```bash
# Install Trivy

# On Linux
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan the image
trivy image hello-world:local
```

### Run Linter Locally

```bash
# Install dependencies
npm install

# Run ESLint
npx eslint .
```

## Screenshots

### Successful Pipeline Run

![CI Pipeline Success](screenshots/ci-pipeline-success.png)
![CD Pipeline Success](screenshots/cd-pipeline-success.png)

### Application Response

![Application Response](screenshots/app-response.png)

## Troubleshooting

### Pipeline Fails at Security Scan

**Issue**: Trivy finds HIGH/CRITICAL vulnerabilities

**Solution**:
1. Check the Trivy scan output in GitHub Actions logs
2. Update base image to latest version
3. Update Node.js dependencies: `npm update`
4. If false positive, adjust Trivy configuration in `.github/workflows/ci.yaml`

### Cannot Access Application

**Issue**: LoadBalancer URL not accessible

**Solution**:
```bash
# Check service status
kubectl get svc hello-world -n default

# Check pods are running
kubectl get pods -n default -l app=hello-world

# Check pod logs
kubectl logs -n default -l app=hello-world

# Describe service for events
kubectl describe svc hello-world -n default
```

### Terraform Apply Fails

**Issue**: Resource creation errors

**Solution**:
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check region availability
aws ec2 describe-availability-zones --region us-east-1

# Check service quotas
aws service-quotas list-service-quotas --service-code eks

# Destroy and retry
terraform destroy
terraform apply
```

### GitHub Actions Cannot Assume Role

**Issue**: "An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation"

**Solution**:
1. Verify the IAM role ARN in GitHub secrets matches Terraform output
2. Update the trust policy in `iam-oidc.tf` with your exact GitHub repository path
3. Ensure OIDC provider is created: `terraform apply`
4. Check IAM role permissions in AWS console

## Cleanup

```bash
# Delete Kubernetes resources first
kubectl delete -f k8s/

# Delete ECR images (optional, to avoid orphan images)
aws ecr list-images --repository-name hello-world-dev --query 'imageIds[*]' --output json | \
  jq -r '.[] | "--image-ids imageDigest=\(.imageDigest)"' | \
  xargs -I {} aws ecr batch-delete-image --repository-name hello-world-dev {}

# Destroy Terraform infrastructure
cd terraform
terraform destroy
# Type 'yes' when prompted
```

## Project Structure

```
interview-hello-world/
├── .github/
│   └── workflows/
│       ├── ci.yaml              # CI pipeline
│       └── cd.yaml              # CD pipeline
├── k8s/
│   ├── deployment.yaml          # Kubernetes deployment
│   ├── service.yaml             # LoadBalancer service
│   └── namespace.yaml           # Namespace definition
├── terraform/
│   ├── providers.tf             # Provider configuration
│   ├── variables.tf             # Input variables
│   ├── vpc.tf                   # VPC and networking
│   ├── ecr.tf                   # ECR repository
│   ├── eks.tf                   # EKS cluster
│   ├── iam-oidc.tf              # OIDC providers and IAM roles
│   ├── outputs.tf               # Output values
│   ├── terraform.tfvars.example # Example variables file
│   └── .gitignore               # Terraform gitignore
├── scripts/
│   └── deploy.sh                # Manual deployment script
├── Dockerfile                   # Multi-stage Docker build
├── server.js                    # Node.js application
├── package.json                 # NPM dependencies
├── eslint.config.js             # ESLint configuration
├── .gitignore                   # Git ignore rules
└── README.md                    # This file
```

## Key Features Implemented

### Task 1: Infrastructure (Terraform) ✅

- ✅ Private ECR repository
- ✅ EKS cluster (2 worker nodes)
- ✅ Complete VPC with public/private subnets
- ✅ NAT Gateway for private subnet internet access
- ✅ Security groups and IAM roles
- ✅ Using community modules (terraform-aws-modules)

### Task 2: CI Pipeline ✅

- ✅ Triggers on main branch commits
- ✅ Linting with ESLint
- ✅ Docker image build
- ✅ Security scanning with Trivy
- ✅ Pipeline fails on HIGH/CRITICAL vulnerabilities
- ✅ Push to ECR with proper authentication

### Task 3: CD Pipeline ✅

- ✅ Runs automatically after CI success
- ✅ OIDC authentication (no long-lived keys)
- ✅ Connects to EKS cluster
- ✅ Deploys with new image tag
- ✅ LoadBalancer for public access

To get your LoadBalancer URL:
```bash
kubectl get svc hello-world -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Built with ❤️ using Terraform, AWS EKS, and GitHub Actions**

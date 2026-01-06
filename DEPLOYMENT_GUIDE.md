# 🚀 Clean Deployment Guide

**Use this guide for a fresh deployment from scratch (no import needed!)**

---

## Prerequisites

### 1. **AWS Account Setup**
```bash
# Configure AWS CLI with your credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1)
```

### 2. **Required IAM Permissions**

Your AWS user needs these permissions (attach the policy in AWS Console):
- EC2 (Full Access)
- EKS (Full Access)
- ECR (Full Access)
- IAM (CreateRole, AttachRolePolicy, CreateOpenIDConnectProvider)
- CloudWatch Logs (including `ListTagsForResource`)
- KMS (CreateKey, CreateAlias)
- ELB (Full Access)

**See:** `terraform/required-iam-policy.json` for complete policy

---

## 🎯 Step-by-Step Deployment (Clean Start)

### **Step 1: Clone Repository**

```bash
git clone https://github.com/Tejas-24ytj/interview-hello-world.git
cd interview-hello-world
```

---

### **Step 2: Configure Terraform Variables**

Create `terraform/terraform.tfvars`:

```hcl
project_name = "hello-world"
environment = "dev"
aws_region = "us-east-1"
cluster_version = "1.33"

# Update with YOUR GitHub username
github_repository_pattern = "repo:YOUR_USERNAME/interview-hello-world:*"

# Node group configuration
instance_types = ["t3.medium"]
desired_size = 2
min_size = 1
max_size = 3
```

**Important:** Replace `YOUR_USERNAME` and `YourName`!

---

### **Step 3: Initialize Terraform**

```bash
cd terraform
terraform init
```

**Expected output:**
```
Terraform has been successfully initialized!
```

---

### **Step 4: Preview Changes**

```bash
terraform plan
```

Review the plan - should show ~31 resources to create.

---

### **Step 5: Deploy Infrastructure**

```bash
terraform apply -auto-approve
```

**Time:** ~12-15 minutes

**What gets created:**
- ✅ VPC with 3 public + 3 private subnets
- ✅ NAT Gateway & Internet Gateway
- ✅ EKS Cluster (v1.33)
- ✅ 2 Worker Nodes (t3.medium)
- ✅ ECR Repository
- ✅ IAM Roles (EKS, Node Group, GitHub Actions)
- ✅ OIDC Providers (EKS, GitHub)
- ✅ Security Groups
- ✅ CloudWatch Log Groups
- ✅ KMS Keys

---

### **Step 6: Configure kubectl**

```bash
# Get the command from terraform output
terraform output configure_kubectl

# Or run directly:
aws eks update-kubeconfig --region us-east-1 --name hello-world-dev
```

**Verify:**
```bash
kubectl get nodes
# Should show 2 nodes in Ready state
```

---

### **Step 7: Configure GitHub Actions**

#### 7a. Get GitHub Actions Role ARN
```bash
terraform output github_actions_role_arn
```

Copy the output (example: `arn:aws:iam::123456789012:role/hello-world-dev-github-actions`)

#### 7b. Add GitHub Secret

1. Go to: `https://github.com/YOUR_USERNAME/interview-hello-world/settings/secrets/actions/new`
2. Click **"New repository secret"**
3. **Name**: `AWS_ROLE_ARN`
4. **Secret**: (paste the ARN from step 7a)
5. Click **"Add secret"**

---

### **Step 8: Trigger CI/CD Pipeline**

```bash
# Make any commit to trigger the pipeline
git commit --allow-empty -m "Trigger CI/CD deployment"
git push origin main
```

**Monitor:** Go to `https://github.com/YOUR_USERNAME/interview-hello-world/actions`

**Pipeline stages:**
1. ✅ Lint (ESLint)
2. ✅ Build Docker Image
3. ✅ Security Scan (Trivy - fails only on CRITICAL)
4. ✅ Push to ECR
5. ✅ Deploy to EKS

**Time:** ~5-7 minutes

---

### **Step 9: Get Application URL**

```bash
kubectl get svc hello-world -n default
```

**Look for:** `EXTERNAL-IP` column (LoadBalancer URL)

Example: `a7bd8295-1319766534.us-east-1.elb.amazonaws.com`

**Test:**
```bash
curl http://YOUR_LOADBALANCER_URL
# Should return: {"message":"Hello from EKS","version":"1.0","timestamp":"..."}
```

---

## 🎉 Deployment Complete!

Your application is now live and accessible via LoadBalancer URL!

---

## 🧹 Clean Up (Destroy Resources)

When you're done testing:

```bash
cd terraform
terraform destroy -auto-approve
```

**Time:** ~10-15 minutes

**What gets deleted:**
- All AWS resources created by Terraform
- LoadBalancer, EKS cluster, nodes, VPC, etc.

**Important:** This does NOT delete:
- ECR images (delete manually if needed)
- CloudWatch Logs (retention policy applies)
- S3 buckets (if you configured remote state)

---

## ❓ Common Questions

### **Q: Do I need to import resources?**
**A:** No! Only if:
- You lost your `terraform.tfstate` file
- Someone manually created resources in AWS Console
- You're recovering from a partial deployment

For clean deployments, **no import needed!**

---

### **Q: What if I get "OIDC provider already exists"?**
**A:** This shouldn't happen anymore! The fix is in `terraform/modules/iam/main.tf` - it now uses `data` source instead of creating a duplicate.

**If it still happens:**
```bash
# Find the OIDC provider ARN
terraform output eks_cluster_oidc_issuer_url

# Import it
terraform import module.iam.aws_iam_openid_connect_provider.eks \
  arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID
```

---

### **Q: What if deployment fails?**
**A:** Check `TROUBLESHOOTING.md` for all common issues and fixes!

---

## 📋 Quick Command Reference

```bash
# Terraform
terraform init                  # Initialize
terraform plan                  # Preview changes
terraform apply                 # Deploy
terraform destroy               # Clean up
terraform output                # Show outputs

# kubectl
kubectl get nodes               # Check nodes
kubectl get pods -n default     # Check pods
kubectl get svc -n default      # Check services
kubectl logs <pod-name>         # View logs
kubectl describe pod <pod-name> # Debug pod issues

# AWS CLI
aws eks list-clusters           # List EKS clusters
aws ecr describe-repositories   # List ECR repos
aws iam list-attached-user-policies --user-name <user>  # Check permissions
```

---

## 🎯 Success Checklist

- [ ] AWS credentials configured
- [ ] IAM permissions attached
- [ ] Repository cloned
- [ ] `terraform.tfvars` created with YOUR values
- [ ] `terraform init` successful
- [ ] `terraform apply` successful (all 31 resources created)
- [ ] kubectl configured and nodes showing
- [ ] GitHub secret `AWS_ROLE_ARN` added
- [ ] Code pushed to GitHub
- [ ] Pipeline completed successfully (all green)
- [ ] LoadBalancer URL accessible
- [ ] Application responding to requests

---

## 🔄 Next Time Deployment

If you destroy and want to deploy again:

```bash
# 1. Same configuration
terraform apply -auto-approve

# 2. Configure kubectl again
aws eks update-kubeconfig --region us-east-1 --name hello-world-dev

# 3. Push code (if needed)
git push origin main

# 4. Get LoadBalancer URL
kubectl get svc hello-world -n default
```

**That's it! No import, no special steps!** 🚀

---

## 📚 Additional Resources

- **Troubleshooting:** See `TROUBLESHOOTING.md`
- **Architecture:** See `README.md`
- **Terraform Modules:** See `terraform/modules/`

---

*Last updated: 2026-01-06*  
*Maintained by: Tejas23*


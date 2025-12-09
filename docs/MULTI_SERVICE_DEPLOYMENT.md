# Multi-Service Deployment Guide

> **📌 Implementation Note**: This guide describes the current inline deployment process approach. The `.octopus/process-templates/` directory contains future implementations using Process Templates, which will be available once the Octopus Terraform Provider adds support for Deployment Processes using Process Templates.

---

## Overview

This Terraform configuration supports deploying multiple microservices, each with:
- ✅ Dedicated Octopus project per service
- ✅ Shared environments (Development, Test, Production)
- ✅ Shared Standard Lifecycle (Dev → Test → Prod)
- ✅ Shared Project Group (ECS - Canary)
- ✅ Inline deployment process (10 steps per service)
- ✅ Environment-scoped variables mapped to AWS resources

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Octopus Space                         │
├─────────────────────────────────────────────────────────┤
│  Shared Resources (Created Once):                        │
│  - Environments: Development, Test, Production           │
│  - Lifecycle: Standard Lifecycle (Dev → Test → Prod)    │
│  - Project Group: ECS - Canary                          │
├─────────────────────────────────────────────────────────┤
│  Per-Service Resources:                                  │
│                                                          │
│  ┌─────────────────────────────────────┐                │
│  │ payment-api                         │                │
│  │ - Uses: Standard Lifecycle          │                │
│  │ - Process: 10 inline steps          │                │
│  │ - Variables: payment-api-* ARNs     │                │
│  │ - AWS: ECS, ALB, Target Groups      │                │
│  └─────────────────────────────────────┘                │
│                                                          │
│  ┌─────────────────────────────────────┐                │
│  │ user-service                        │                │
│  │ - Uses: Standard Lifecycle          │                │
│  │ - Process: 10 inline steps          │                │
│  │ - Variables: user-service-* ARNs    │                │
│  │ - AWS: ECS, ALB, Target Groups      │                │
│  └─────────────────────────────────────┘                │
│                                                          │
│  ┌─────────────────────────────────────┐                │
│  │ order-api                           │                │
│  │ - Uses: Standard Lifecycle          │                │
│  │ - Process: 10 inline steps          │                │
│  │ - Variables: order-api-* ARNs       │                │
│  │ - AWS: ECS, ALB, Target Groups      │                │
│  └─────────────────────────────────────┘                │
└─────────────────────────────────────────────────────────┘
```

## Prerequisites

### Current Implementation (No Special Prerequisites)

The current implementation uses inline deployment processes and requires no special setup:

1. ✅ **Terraform** >= 1.5.0
2. ✅ **AWS credentials** configured
3. ✅ **Octopus Deploy** instance with API access
4. ✅ **VPC** with subnets and security groups

That's it! Environments, lifecycle, project group, and deployment process are all created automatically by Terraform.

### Future Implementation (Process Templates)

> **⚠️ Not Yet Available**: The following prerequisites describe the future approach using Process Templates. Skip this section for now.

<details>
<summary>Click to expand future prerequisites</summary>

#### 1. Deploy Process Template to Platform Hub

First, ensure the OCL process template is deployed:

```bash
# The template should be in your Git repository
.octopus/process-templates/ecs-canary-deployment/
├── deployment_process.ocl
├── template.json
└── README.md

# After committing, sync Platform Hub with your repository
# Navigate to: Platform Hub → Process Templates
# Verify: "Deploy Process - ECS Canary Deployment" appears
# Copy the Process Template ID (e.g., "ProcessTemplates-1")
```

#### 2. Get Process Template ID

```bash
# Option 1: Via Octopus Web UI
# 1. Go to Platform Hub → Process Templates
# 2. Click "Deploy Process - ECS Canary Deployment"
# 3. Copy ID from URL or details page

# Option 2: Via Octopus CLI
octopus process-template list --space "Default"

# Option 3: Via API
curl -H "X-Octopus-ApiKey: $OCTOPUS_API_KEY" \
  "https://your-instance.octopus.app/api/Spaces-1/processtemplates"
```

**When Available**: You'll configure this in `terraform.tfvars`:
```hcl
octopus_process_template_id = "ProcessTemplates-1"
```

</details>

---

## Deployment Approaches

### Option 1: Terraform Workspaces (Recommended)

Use Terraform workspaces to manage multiple services with the same configuration:

```bash
# Setup for payment-api
terraform workspace new payment-api
terraform workspace select payment-api
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: service_name = "payment-api"
terraform init
terraform apply

# Setup for user-service
terraform workspace new user-service
terraform workspace select user-service
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: service_name = "user-service"
terraform apply

# Setup for order-api
terraform workspace new order-api
terraform workspace select order-api
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: service_name = "order-api"
terraform apply
```

### Option 2: Separate Directories

Create isolated configurations for each service:

```bash
# Directory structure
.octopus/
├── payment-api/
│   ├── backend.tf
│   ├── terraform.tfvars
│   └── main.tf (symlinks to shared modules)
├── user-service/
│   ├── backend.tf
│   ├── terraform.tfvars
│   └── main.tf
└── order-api/
    ├── backend.tf
    ├── terraform.tfvars
    └── main.tf

# Use the provided setup script
./scripts/setup-microservice.sh payment-api
./scripts/setup-microservice.sh user-service
./scripts/setup-microservice.sh order-api

# Deploy each service
cd .octopus/payment-api && terraform init && terraform apply
cd ../user-service && terraform init && terraform apply
cd ../order-api && terraform init && terraform apply
```

### Option 3: Terragrunt (For Scale)

For managing 10+ services, use Terragrunt:

```hcl
# terragrunt.hcl (per service)
include {
  path = find_in_parent_folders()
}

inputs = {
  service_name = "payment-api"
  container_image = "myorg/payment-api"
  # ... other service-specific values
}
```

## Step-by-Step: Deploy Your First Service

### 1. Set Service Name

```bash
# Edit terraform.tfvars
service_name = "payment-api"
```

### 2. Configure AWS Resources

```bash
# Edit terraform.tfvars
vpc_id = "vpc-xxxxx"
subnet_ids = ["subnet-1", "subnet-2"]
security_group_ids = ["sg-xxxxx"]
alb_subnet_ids = ["subnet-pub1", "subnet-pub2"]
container_image = "myorg/payment-api"
```

### 3. Configure Octopus

```bash
# Edit terraform.tfvars
octopus_server_url = "https://your-instance.octopus.app"
octopus_space_name = "Default"
octopus_aws_account_name = "sales-demo-oidc"
octopus_worker_pool_id = "WorkerPools-64"
```

### 4. Deploy Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

### 5. Verify in Octopus

```bash
# Check what was created:
# 1. Environments: Development, Test, Production (shared)
# 2. Lifecycle: Standard Lifecycle (shared)
# 3. Project Group: ECS - Canary (shared)
# 4. Project: payment-api
# 5. Deployment Process: 10 inline steps
# 6. Variables: Environment-scoped ARNs for ALB, target groups, ECS

# View in UI
open "https://your-instance.octopus.app/app#/Spaces-1/projects/Projects-XXX"
```

### 6. Create and Deploy Release

```bash
# Via Octopus UI
# 1. Navigate to payment-api project
# 2. Click "Create Release"
# 3. Deploy to Development
# 4. Approve manual gates during canary deployment
# 5. Promote to Test, then Production

# Via Octopus CLI
octopus release create --project "payment-api" --version "1.0.0"
octopus release deploy --project "payment-api" --version "1.0.0" --environment "Development"
```

## What Gets Created

### Per Service (payment-api example)

#### AWS Resources
- **ECS Clusters** (if `create_ecs_clusters = true`):
  - `payment-api-cluster-dev`
  - `payment-api-cluster-test`
  - `payment-api-cluster-prod`
  
- **ECS Services**:
  - `payment-api-dev`
  - `payment-api-test`
  - `payment-api-prod`
  
- **Application Load Balancers**:
  - `payment-api-alb-dev`
  - `payment-api-alb-test`
  - `payment-api-alb-prod`
  
- **Target Groups** (Blue/Green per environment):
  - `payment-api-blue-development`, `payment-api-green-development`
  - `payment-api-blue-test`, `payment-api-green-test`
  - `payment-api-blue-production`, `payment-api-green-production`
  
- **Task Sets**: Blue and Green per environment
- **Listener Rules**: Traffic splitting + testing rules per environment

#### Octopus Resources
- **Project**: `payment-api`
- **Deployment Process**: 10 inline steps for canary deployment
  1. Get Current Stable Stack
  2. Create New Task Definition
  3. Create Canary Task Set (with cleanup)
  4. Wait for Canary Tasks Healthy
  5. Manual Approval - Start Canary
  6. Route 10% Traffic to Canary
  7. Route 50% Traffic to Canary
  8. Manual Decision - Complete or Rollback
  9. Complete Cutover to Canary (with cleanup)
  10. Rollback to Stable (on failure)

- **Variables** (environment-scoped):
  - `ECS.ClusterArn` (per environment)
  - `ECS.ServiceName` (per environment)
  - `ECS.BlueTargetGroupArn` (per environment)
  - `ECS.GreenTargetGroupArn` (per environment)
  - `ECS.ListenerRuleArn` (per environment)
  - `ECS.TestingListenerRuleArn` (per environment)
  - `ECS.SubnetIds` (per environment)
  - `ECS.SecurityGroupIds` (per environment)
  - `AWS.Account` (project-level)
  - `Worker.Pool` (project-level)
  - `AWS.Region` (project-level)

### Shared Resources (One-Time)

Created once, used by all services:

- **Environments**:
  - Development
  - Test
  - Production
  
- **Lifecycle**:
  - Standard Lifecycle (Dev → Test → Prod)

- **Project Group**:
  - ECS - Canary

**Note**: Each service has its own inline deployment process (not shared). In the future, when Process Templates are supported, the deployment process will be shared across all services.

## Managing Multiple Services

### Deploy Second Service

```bash
# Option 1: New Workspace
terraform workspace new user-service
terraform workspace select user-service

# Option 2: New Directory
./scripts/setup-microservice.sh user-service
cd .octopus/user-service

# Edit terraform.tfvars
service_name = "user-service"
container_image = "myorg/user-service"
# (Same Octopus config, AWS account, worker pool)

terraform init
terraform apply
```

### Key Points

1. **Environments are reused** - All services deploy to same Dev/Test/Prod
2. **Lifecycle is reused** - All services follow Dev → Test → Prod
3. **Project group is reused** - All services appear in "ECS - Canary" group
4. **Deployment process is duplicated** - Each service has its own 10-step process (for now)
5. **Variables are unique** - Each service has its own ARNs/configs
6. **AWS resources are isolated** - Each service has dedicated ECS/ALB/TGs

## Variable Usage in Deployment Process

> **Current Implementation**: Variables are referenced directly in the inline deployment process steps. In the future Process Template approach, these will be passed as parameters to the template.

The deployment process references variables using Octopus variable syntax:

```hcl
# Example from Step 1 in terraform/octopus_deployment_process.tf
script_body = <<-EOT
  CLUSTER_NAME=$(echo "#{ECS.ClusterArn}" | awk -F'/' '{print $NF}')
  SERVICE_ARN="arn:aws:ecs:#{AWS.Region}:$(aws sts get-caller-identity --query Account --output text):service/$CLUSTER_NAME/#{ECS.ServiceName}"
  # ... etc
EOT
```

### How It Works

1. **Terraform creates AWS resources** (ALB, target groups, ECS)
2. **Terraform creates Octopus variables** with ARNs from AWS resources
3. **Variables are scoped by environment** (Development/Test/Production)
4. **Deployment process references variables** via `#{VariableName}` syntax
5. **Values resolve at deployment time** based on target environment

### Variable Scoping Example

```
Project: payment-api
├── AWS.Account (project-level)
│   Value: "Accounts-123" (AWS OIDC account)
│
├── Worker.Pool (project-level)
│   Value: "WorkerPools-64"
│
└── ECS.ClusterArn (environment-scoped)
    ├── Development: "arn:aws:ecs:us-east-1:xxx:cluster/payment-api-cluster-dev"
    ├── Test: "arn:aws:ecs:us-east-1:xxx:cluster/payment-api-cluster-test"
    └── Production: "arn:aws:ecs:us-east-1:xxx:cluster/payment-api-cluster-prod"
```

## Troubleshooting

### Error: Environments already exist

This is expected! The Terraform will:
1. Try to query existing environments via `data` sources
2. Use existing environments if found
3. Create new environments only if they don't exist

No action needed - this is by design.

### Error: Lifecycle already exists

Same as above - the Terraform will:
1. Query for existing "Standard Lifecycle"
2. Use it if found
3. Create only if missing

### Error: Project group already exists

Same pattern - Terraform will:
1. Query for existing "ECS - Canary" project group
2. Use it if found
3. Create only if missing

### Multiple services deploying simultaneously

To avoid conflicts:

```bash
# Use separate workspaces or directories
terraform workspace new service-a
terraform workspace new service-b

# Or use Terraform locks (S3 backend)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "microservices/${service_name}/terraform.tfstate"
    dynamodb_table = "terraform-locks"
  }
}
```

### Deployment process not updating

If you need to update an existing project's deployment process:

```bash
# In terraform.tfvars
create_deployment_process = true

terraform apply
```

## Best Practices

1. **Use workspace naming**: `<service-name>` (e.g., `payment-api`)
2. **Standardize container images**: `<org>/<service-name>` pattern
3. **Tag resources consistently**: All resources tagged with `Service=<service-name>`
4. **Use remote state**: S3 backend with DynamoDB locking
5. **Separate state per service**: Isolate blast radius
6. **Document service list**: Maintain registry of deployed services
7. **Review deployment process**: Each service gets the same 10-step process

## Future: Migration to Process Templates

> **🔜 When Process Template support is added to the Terraform provider**, you'll be able to migrate from inline processes to shared templates:

### Benefits of Process Templates (Future)
- ✅ Define deployment process once
- ✅ Share across all services
- ✅ Update once, affects all services
- ✅ Manage in Git via OCL
- ✅ Reduce Terraform complexity

### Migration Path (When Available)
1. Deploy OCL process template to Platform Hub
2. Get process template ID
3. Update `terraform.tfvars`:
   ```hcl
   octopus_process_template_id = "ProcessTemplates-1"
   create_deployment_process = true
   ```
4. Run `terraform apply` to update existing projects
5. Verify process in Octopus UI

## Example CI/CD Integration

```yaml
# .github/workflows/deploy-service.yaml
name: Deploy Service

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Configure workspace
        run: |
          terraform workspace new ${{ github.event.repository.name }} || true
          terraform workspace select ${{ github.event.repository.name }}
      
      - name: Deploy infrastructure
        run: |
          terraform init
          terraform apply -auto-approve
        env:
          TF_VAR_service_name: ${{ github.event.repository.name }}
          TF_VAR_octopus_api_key: ${{ secrets.OCTOPUS_API_KEY }}
```

## Support

- See `docs/developer/DEVELOPER_QUICKSTART.md` for developer guide
- See `docs/QUICK_REFERENCE.md` for quick reference
- Check Octopus Community Slack for help

## Summary

✅ **Current Implementation**:
- Inline deployment process (10 steps per service)
- Shared environments, lifecycle, and project group
- Each service is independent
- Traffic flow: 10% → 50% → 100%

✅ **Easy onboarding**: Set `service_name`, run `terraform apply`

✅ **Isolated resources**: Each service has dedicated AWS resources

✅ **Automated mapping**: Variables automatically scope to environments

🔜 **Future Enhancement**: Process template sharing when provider adds support
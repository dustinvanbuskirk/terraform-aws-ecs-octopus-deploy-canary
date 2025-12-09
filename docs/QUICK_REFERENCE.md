# Quick Reference: Inline Deployment Process

> **📌 Current Implementation**: This guide describes the inline deployment process approach currently in use. For information about the future Process Template approach, see `.octopus/process-templates/ecs-canary-deployment/README.md`.

---

## Current Implementation

### Architecture
- ✅ Inline deployment process (10 steps in Terraform)
- ✅ Environments created automatically (or reused if they exist)
- ✅ Lifecycle created automatically (or reused if it exists)
- ✅ Project group created automatically (or reused if it exists)
- ✅ Each service has its own deployment process instance

### NOT Used (Yet)
- ❌ Process Templates (waiting for Terraform provider support)
- ❌ OCL files for deployment process
- ❌ Shared deployment process across services

## Quick Start

### 1. Configure terraform.tfvars

```hcl
# Service name (the magic variable)
service_name = "payment-api"

# AWS Configuration
vpc_id = "vpc-xxxxx"
subnet_ids = ["subnet-1", "subnet-2"]
security_group_ids = ["sg-xxxxx"]
alb_subnet_ids = ["subnet-pub1", "subnet-pub2"]
container_image = "myorg/payment-api"

# Octopus Configuration
octopus_server_url = "https://your-instance.octopus.app"
octopus_space_name = "Default"
octopus_aws_account_name = "sales-demo-oidc"
octopus_worker_pool_id = "WorkerPools-64"

# Process creation (true for new projects, which is most cases)
create_deployment_process = true
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 3. What Gets Created

**Shared Resources** (created once, reused by all services):
- Environments: Development, Test, Production
- Lifecycle: Standard Lifecycle (Dev → Test → Prod)
- Project Group: ECS - Canary

**Per-Service Resources**:
- Octopus Project: payment-api
- AWS Resources: ECS clusters, services, ALBs, target groups
- Deployment Process: 10 inline steps (see below)
- Variables: Environment-scoped ARNs and configuration

## Deployment Process Steps

The inline process includes 10 steps:

| Step | Name | Type | Purpose |
|------|------|------|---------|
| 1 | Get Current Stable Stack | Script | Identify current stable stack |
| 2 | Create New Task Definition | Script | Create new ECS task definition |
| 3 | Create Canary Task Set | Script | Deploy to inactive stack (with cleanup) |
| 4 | Wait for Canary Tasks Healthy | Script | Wait for health checks |
| 5 | Manual Approval - Start Canary | Manual | Gate before routing traffic |
| 6 | Route 10% Traffic to Canary | Script | Route 10% traffic |
| 7 | Route 50% Traffic to Canary | Script | Route 50% traffic |
| 8 | Manual Decision - Complete or Rollback | Manual | Final gate |
| 9 | Complete Cutover to Canary | Script | Complete cutover + cleanup old stable |
| 10 | Rollback to Stable | Script | On failure, rollback |

**Key Features**:
- **Step 3**: Deletes existing canary task set before creating new one (prevents conflicts)
- **Step 9**: Routes 100% traffic AND automatically cleans up old stable task set
- **Step 10**: Runs only on failure (condition: "Failure")
- All scripts use AWS OIDC authentication
- Manual gates allow metric review between traffic increases
- Simplified traffic progression: 10% → 50% → 100%

## Action Names for Variable References

When referencing step outputs in variables, use these exact action names:

```hcl
#{Octopus.Action[Get Stable Stack Tag].Output.StableStack}
#{Octopus.Action[Register Task Definition].Output.NewTaskDefinition}
#{Octopus.Action[Create Canary Task Set].Output.CanaryExternalId}
```

**Note**: Action names may differ slightly from step names. Always check `terraform/octopus_deployment_process.tf` for exact names.

## Variable Scoping

Terraform creates separate variable resources for each environment:

```hcl
# Example: ECS.ClusterArn is created 3 times
resource "octopusdeploy_variable" "cluster_arn_dev" {
  name  = "ECS.ClusterArn"
  value = "arn:aws:ecs:us-east-1:xxx:cluster/payment-api-cluster-dev"
  scope { environments = [development_id] }
}

resource "octopusdeploy_variable" "cluster_arn_test" {
  name  = "ECS.ClusterArn"
  value = "arn:aws:ecs:us-east-1:xxx:cluster/payment-api-cluster-test"
  scope { environments = [test_id] }
}

resource "octopusdeploy_variable" "cluster_arn_prod" {
  name  = "ECS.ClusterArn"
  value = "arn:aws:ecs:us-east-1:xxx:cluster/payment-api-cluster-prod"
  scope { environments = [production_id] }
}
```

At deployment time, Octopus resolves `#{ECS.ClusterArn}` to the appropriate value based on target environment.

### All Environment-Scoped Variables

Each of these is created 3 times (dev, test, prod):

- `ECS.ClusterArn` - ECS Cluster ARN
- `ECS.ServiceName` - ECS Service name
- `ECS.BlueTargetGroupArn` - Blue target group ARN
- `ECS.GreenTargetGroupArn` - Green target group ARN
- `ECS.ListenerRuleArn` - Traffic splitting listener rule ARN
- `ECS.TestingListenerRuleArn` - Testing listener rule ARN
- `ECS.SubnetIds` - Comma-separated subnet IDs
- `ECS.SecurityGroupIds` - Comma-separated security group IDs

### Project-Level Variables

These are created once per project:

- `AWS.Account` - AWS OIDC account ID
- `Worker.Pool` - Worker pool ID
- `AWS.Region` - AWS region

## Deploying Multiple Services

### Option 1: Terraform Workspaces
```bash
terraform workspace new user-service
terraform workspace select user-service
# Edit terraform.tfvars: service_name = "user-service"
terraform apply
```

### Option 2: Separate Directories
```bash
./scripts/setup-microservice.sh user-service
cd .octopus/user-service
# Edit terraform.tfvars
terraform init && terraform apply
```

## Troubleshooting

### "Environments already exist"
✅ **This is normal!** Terraform will reuse existing environments.

### "Lifecycle already exist"
✅ **This is normal!** Terraform will reuse the existing lifecycle.

### "Project group already exists"
✅ **This is normal!** Terraform will reuse the existing project group.

### Deployment process not created
Check `create_deployment_process` variable:
- For **NEW projects**: Set to `true` (or omit, will create anyway due to `!local.project_exists`)
- For **EXISTING projects**: Set to `true` to update process

### Task set conflicts
If you see errors about task sets already existing, the cleanup logic in Step 3 handles this automatically. If issues persist:
```bash
# Manually delete task set via AWS CLI
aws ecs delete-task-set \
  --cluster <cluster-arn> \
  --service <service-name> \
  --task-set <task-set-id> \
  --force
```

## Files Reference

**Current Implementation Files**:
- `terraform/octopus_deployment_process.tf` - 10 inline steps
- `terraform/octopus_environments.tf` - Environments and lifecycle
- `terraform/octopus_project_group.tf` - Project group
- `terraform/octopus_variables.tf` - Environment-scoped variables
- `terraform/octopus_project.tf` - Project definition

**Future Implementation Files** (not yet usable):
- `.octopus/process-templates/ecs-canary-deployment/deployment_process.ocl`
- `.octopus/process-templates/ecs-canary-deployment/README.md`

## Step Details

### Step 1: Get Stable Stack Tag
```bash
# Identifies current stable stack (Blue or Green)
# Sets: StableStack, StableTaskSetArn, StableTaskDefinition
STACK=$(aws ecs list-tags-for-resource ... | jq -r '.tags[] | select(.key == "StableStack") | .value')
```

### Step 3: Create Canary Task Set (with cleanup)
```bash
# Deletes existing canary task set if it exists (prevents conflicts)
CANARY_TASKSET_ID=$(aws ecs describe-services ...)
if [ ! -z "$CANARY_TASKSET_ID" ] && [ "$CANARY_TASKSET_ID" != "null" ]; then
  aws ecs delete-task-set ... --force
  sleep 15
fi
# Then creates new canary task set
```

### Step 9: Complete Cutover (with cleanup)
```bash
# 1. Routes 100% traffic to canary
aws elbv2 modify-rule ... --actions "[{...Weight=100...}]"

# 2. Updates StableStack tag
aws ecs tag-resource ... --tags key=StableStack,value=$NEW_STABLE_STACK

# 3. IMPORTANT: Cleans up old stable task set
OLD_TASKSET_ID=$(aws ecs describe-services ...)
aws ecs delete-task-set ... --force
```

This cleanup in Step 9 is critical - it prevents accumulation of old task sets over multiple deployments.

## Future: Process Template Approach

> **🔜 Coming Soon**: Once the Octopus Terraform Provider adds support for Process Templates in deployment processes, you'll be able to:
> - Define the deployment process once in OCL
> - Share it across all services
> - Update all services by updating the template
>
> The OCL files are ready in `.octopus/process-templates/ecs-canary-deployment/` for future use.

### Benefits When Available

**Current (Inline)**:
- ✅ Works now
- ❌ Process duplicated per service
- ❌ Updates require Terraform changes

**Future (Process Template)**:
- ✅ Process shared across services
- ✅ Update once, affects all services
- ✅ Managed in Git via OCL
- ❌ Requires provider support (not yet available)

## Summary

**Use Now**: Inline deployment process approach
- Defined in: `terraform/octopus_deployment_process.tf`
- Status: Fully functional
- Supports: All 10 canary deployment steps
- Traffic flow: 10% → 50% → 100%

**Use Later**: Process template approach
- Defined in: `.octopus/process-templates/ecs-canary-deployment/`
- Status: Ready for future use
- Requires: Terraform provider support for process templates
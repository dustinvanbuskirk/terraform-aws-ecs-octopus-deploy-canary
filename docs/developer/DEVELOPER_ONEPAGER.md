# Developer One-Pager

> **📌 Current Implementation**: This guide describes the inline deployment process approach currently in use. For information about the future Process Template approach, see `.octopus/process-templates/ecs-canary-deployment/README.md`.

---

## Deploy Your Microservice in 5 Minutes

```bash
./scripts/setup-microservice.sh my-service
vim .octopus/my-service/terraform.tfvars
cd .octopus/my-service && terraform init && terraform apply
```

## The Magic: ONE Variable

```hcl
service_name = "payment-api"
```

Generates:
- **Octopus Project**: payment-api
- **ECS Services**: payment-api-dev, payment-api-test, payment-api-prod
- **Load Balancers**: payment-api-alb-dev, payment-api-alb-test, payment-api-alb-prod
- **Target Groups**: payment-api-blue-development, payment-api-green-development
- **Deployment Process**: 10-step canary deployment
- **All resources tagged**: Service=payment-api

## What You Configure (12 lines)

```hcl
# 1. Service name (the magic variable)
service_name = "payment-api"

# 2-5. VPC and subnet IDs
vpc_id = "vpc-xxxxx"
subnet_ids = ["subnet-1", "subnet-2"]
security_group_ids = ["sg-xxxxx"]
alb_subnet_ids = ["subnet-pub1", "subnet-pub2"]

# 6. Container image
container_image = "myorg/payment-api"

# 7-10. Octopus server details
octopus_server_url = "https://your-instance.octopus.app"
octopus_space_name = "Default"
octopus_aws_account_name = "sales-demo-oidc"
octopus_worker_pool_id = "WorkerPools-64"
```

## What You Get (40+ resources)

### Octopus Deploy
- ✅ Project: payment-api
- ✅ Environments: Development, Test, Production (shared)
- ✅ Lifecycle: Standard (Dev → Test → Prod, shared)
- ✅ Project Group: ECS - Canary (shared)
- ✅ Deployment Process: 10 inline steps
- ✅ Variables: 27 environment-scoped variables

### AWS Resources (per environment = 3x)
- ✅ ECS Cluster: payment-api-cluster-{env}
- ✅ ECS Service: payment-api-{env}
- ✅ Task Definition: payment-api-{env}
- ✅ Blue Task Set: OctopusBlueStack
- ✅ Green Task Set: OctopusGreenStack
- ✅ Application Load Balancer: payment-api-alb-{env}
- ✅ Blue Target Group: payment-api-blue-{env}
- ✅ Green Target Group: payment-api-green-{env}
- ✅ Listener: Port 80
- ✅ Traffic Split Rule: Priority 10
- ✅ Testing Rule: Priority 5 (?test=true)
- ✅ Security Group (if not provided)

**Total AWS Resources**: 36 (12 per environment × 3 environments)

## Deployment Process Steps

Your service gets a complete 10-step canary deployment process:

| Step | Type | Purpose |
|------|------|---------|
| 1. Get Current Stable Stack | Script | Identify Blue/Green stable |
| 2. Create New Task Definition | Script | Register new ECS task |
| 3. Create Canary Task Set | Script | Deploy to inactive stack |
| 4. Wait for Canary Tasks Healthy | Script | Health check monitoring |
| 5. Manual Approval - Start Canary | Manual | Gate before traffic |
| 6. Route 10% Traffic to Canary | Script | 10% traffic to canary |
| 7. Route 50% Traffic to Canary | Script | Increase to 50% |
| 8. Manual Decision | Manual | Final review |
| 9. Complete Cutover | Script | 100% + cleanup |
| 10. Rollback to Stable | Script | On failure only |

**Traffic Flow**: 0% → 10% → 50% → 100%

## How It Works

```
1. Set service_name = "payment-api"
   ↓
2. Terraform creates AWS resources
   ↓
3. Terraform creates Octopus project
   ↓
4. Terraform creates deployment process (10 steps)
   ↓
5. Terraform creates variables (scoped per environment)
   ↓
6. You create a release in Octopus
   ↓
7. Deploy to Development
   ↓
8. Canary deployment: 10% → 50% → 100%
   ↓
9. Promote to Test
   ↓
10. Promote to Production
```

## Example: Complete Workflow

```bash
# 1. Create configuration directory
./scripts/setup-microservice.sh payment-api

# 2. Edit configuration
cd .octopus/payment-api
vim terraform.tfvars
# Set: service_name, VPC IDs, container image, Octopus details

# 3. Deploy infrastructure
terraform init
terraform plan
terraform apply

# 4. Note the outputs
# - Project URL
# - ALB DNS names
# - Testing URLs

# 5. Create release in Octopus
open "https://your-octopus.app/app#/Spaces-1/projects/payment-api"
# Click "Create Release" → "1.0.0"

# 6. Deploy to Development
# Click "Deploy to Development"
# Approve manual gates at each traffic increment

# 7. Test the deployment
curl "http://payment-api-alb-dev-xxx.us-east-1.elb.amazonaws.com"

# 8. Test canary directly
curl "http://payment-api-alb-dev-xxx.us-east-1.elb.amazonaws.com/?test=true"

# 9. Promote to Test and Production
# Repeat deployment with approvals
```

## Common Commands

```bash
# View Terraform plan
terraform plan

# Apply changes
terraform apply

# View outputs (URLs, ARNs)
terraform output

# Destroy everything
terraform destroy

# Format Terraform files
terraform fmt -recursive

# Switch to different service (workspaces)
terraform workspace select user-service
```

## Multiple Services

Deploy your second service:

```bash
# Option 1: New workspace
terraform workspace new user-service
terraform workspace select user-service
vim terraform.tfvars  # Set service_name = "user-service"
terraform apply

# Option 2: New directory
./scripts/setup-microservice.sh user-service
cd .octopus/user-service
vim terraform.tfvars
terraform init && terraform apply
```

**What's Shared**:
- ✅ Environments (Dev, Test, Prod)
- ✅ Lifecycle (Dev → Test → Prod)
- ✅ Project Group (ECS - Canary)

**What's Unique**:
- ✅ Project (user-service)
- ✅ Deployment Process (10 steps)
- ✅ Variables (user-service ARNs)
- ✅ AWS Resources (user-service-*)

## Troubleshooting

### "Environments already exist"
✅ **Normal!** Terraform reuses existing environments.

### "Lifecycle already exists"
✅ **Normal!** Terraform reuses existing lifecycle.

### "Can't find VPC/subnets"
❌ Check your AWS credentials and VPC ID in terraform.tfvars

### "Octopus API error"
❌ Check your Octopus API key: `export TF_VAR_octopus_api_key="API-XXX"`

### "Worker pool not found"
❌ Update `octopus_worker_pool_id` in terraform.tfvars (e.g., "WorkerPools-64")

## Best Practices

1. **Service Naming**: Keep under 15 characters
   - ✅ payment-api, user-svc, order-api
   - ❌ payment-processing-api-service

2. **Container Images**: Use org/service pattern
   - ✅ myorg/payment-api, myorg/user-service
   - ❌ payment-api, my-payment-api

3. **Workspaces**: One per service
   - ✅ payment-api, user-service, order-api
   - ❌ dev, test, prod (environments are shared!)

4. **Remote State**: Use S3 backend
   ```hcl
   terraform {
     backend "s3" {
       bucket = "my-terraform-state"
       key    = "microservices/payment-api/terraform.tfstate"
     }
   }
   ```

5. **Version Control**: Commit terraform.tfvars (without API keys)
   ```bash
   # Use environment variable for sensitive data
   export TF_VAR_octopus_api_key="API-XXX"
   ```

## What's Next?

1. **Deploy your first service** (follow this guide)
2. **Create a release** in Octopus
3. **Deploy to Development** (with canary gates)
4. **Promote to Test and Production**
5. **Deploy your second service** (repeat pattern)

## Future Enhancement

> **🔜 Process Templates**: In the future, when the Octopus Terraform Provider adds support for Process Templates, you'll be able to share the deployment process across all services instead of duplicating it. The OCL files are ready in `.octopus/process-templates/ecs-canary-deployment/`.

**Benefits When Available**:
- Define process once
- Update all services by updating template
- Managed in Git via OCL

## Quick Reference

| Item | Value |
|------|-------|
| **Main File** | terraform.tfvars |
| **Magic Variable** | service_name |
| **Shared Resources** | Environments, Lifecycle, Project Group |
| **Per-Service Resources** | Project, Process, Variables, AWS |
| **Deployment Steps** | 10 (inline) |
| **Environments** | Development, Test, Production |
| **Traffic Pattern** | 10% → 50% → 100% |
| **Manual Gates** | 2 |

## Resources

- **Full Guide**: docs/MULTI_SERVICE_DEPLOYMENT.md
- **Quick Reference**: docs/QUICK_REFERENCE.md
- **Naming Conventions**: docs/developer/NAMING_CONVENTIONS.md
- **Terraform Files**: terraform/
- **Process Template (Future)**: .octopus/process-templates/

## Support

- **GitHub Issues**: [Your Repo]
- **Octopus Slack**: https://octopus.com/slack
- **Documentation**: Main README.md

---

**Summary**: Set ONE variable (`service_name`), run `terraform apply`, get 40+ resources and a complete canary deployment pipeline!
# Master Index

## Quick Navigation

### Developers
1. docs/developer/DEVELOPER_ONEPAGER.md (2 min) ⭐
2. docs/QUICK_REFERENCE.md (5 min)
3. docs/developer/NAMING_CONVENTIONS.md (10 min)

### Platform Team
1. README.md (15 min) ⭐
2. docs/MULTI_SERVICE_DEPLOYMENT.md (20 min)
3. docs/QUICK_REFERENCE.md (10 min)

### Process Implementation
> **Current Approach**: Inline deployment process (13 steps in Terraform)

**Current Implementation**:
1. terraform/octopus_deployment_process.tf - Inline 13-step process
2. docs/QUICK_REFERENCE.md - Quick reference guide
3. docs/MULTI_SERVICE_DEPLOYMENT.md - Multi-service guide

**Future Implementation** (when Terraform provider adds support):
> **⚠️ Not Yet Available**: Process Templates require Terraform provider support

1. .octopus/process-templates/ecs-canary-deployment/README.md - Future OCL approach
2. .octopus/process-templates/ecs-canary-deployment/deployment_process.ocl - OCL definition

## Complete File List

### Root Level
- README.md - Project overview and quick start
- INDEX.md - This file (navigation guide)
- Makefile - Common Terraform operations
- .editorconfig - Editor configuration
- .gitignore - Git ignore patterns
- backend.tf.example - Remote state backend examples
- terraform.tfvars.example - Configuration example

### Documentation (8 files)
- docs/MULTI_SERVICE_DEPLOYMENT.md - Multi-service deployment guide
- docs/QUICK_REFERENCE.md - Quick reference for current implementation
- docs/developer/DEVELOPER_ONEPAGER.md - 2-minute developer guide
- docs/developer/DEVELOPER_QUICKSTART.md - Detailed developer guide
- docs/developer/NAMING_CONVENTIONS.md - Resource naming patterns

### Terraform Configuration (12 files)
**Core Terraform**:
- terraform/providers.tf - AWS and Octopus providers
- terraform/versions.tf - Required versions
- terraform/variables.tf - Input variables
- terraform/data.tf - Data sources
- terraform/locals.tf - Local values
- terraform/outputs.tf - Output values

**AWS Infrastructure**:
- terraform/ecs.tf - ECS clusters, services, task definitions
- terraform/alb.tf - Application load balancers, target groups

**Octopus Configuration**:
- terraform/octopus_environments.tf - Environments and lifecycle
- terraform/octopus_project_group.tf - Project group
- terraform/octopus_project.tf - Project definition
- terraform/octopus_deployment_process.tf - 13-step inline process
- terraform/octopus_variables.tf - Environment-scoped variables

### Process Templates (3 files) - **FUTURE USE**
> **⚠️ Not Yet Available**: Requires Terraform provider support

- .octopus/process-templates/ecs-canary-deployment/README.md - Future template docs
- .octopus/process-templates/ecs-canary-deployment/deployment_process.ocl - OCL definition
- .octopus/process-templates/ecs-canary-deployment/template.json - Template metadata

### Scripts (2 files)
- scripts/setup-microservice.sh - Create new microservice configuration
- scripts/migrate-provider-v1.sh - Provider migration helper

### GitHub Workflows (1 file)
- .github/workflows/terraform.yaml - CI/CD pipeline

## Documentation by Use Case

### "I want to deploy my first service"
1. Read: README.md (5 min)
2. Read: docs/developer/DEVELOPER_ONEPAGER.md (2 min)
3. Configure: terraform.tfvars (5 min)
4. Deploy: `terraform init && terraform apply` (5 min)

### "I want to deploy multiple services"
1. Read: docs/MULTI_SERVICE_DEPLOYMENT.md (20 min)
2. Choose: Workspaces vs. Separate Directories
3. Deploy each service following the guide

### "I want to understand the deployment process"
1. Read: docs/QUICK_REFERENCE.md - Overview of 13 steps
2. Review: terraform/octopus_deployment_process.tf - Actual implementation
3. Understand: Each step's purpose and logic

### "I want to understand naming conventions"
1. Read: docs/developer/NAMING_CONVENTIONS.md
2. Review: terraform/locals.tf - Auto-naming logic

### "I want to customize the deployment process"
**Current Approach**:
1. Edit: terraform/octopus_deployment_process.tf
2. Modify: Step scripts or add new steps
3. Apply: `terraform apply`

**Future Approach** (when available):
1. Edit: .octopus/process-templates/ecs-canary-deployment/deployment_process.ocl
2. Commit and push to Git
3. Sync: Platform Hub automatically updates
4. All projects using template are updated

### "I'm getting errors during deployment"
1. Check: docs/MULTI_SERVICE_DEPLOYMENT.md - Troubleshooting section
2. Check: docs/QUICK_REFERENCE.md - Troubleshooting section
3. Review: Terraform plan output
4. Verify: AWS resources exist (VPC, subnets, etc.)

## Key Concepts

### Service Name Magic
One variable controls everything:
```hcl
service_name = "payment-api"
```

Generates:
- Octopus Project: payment-api
- ECS Services: payment-api-{env}
- ALBs: payment-api-alb-{env}
- Clusters: payment-api-cluster-{env}
- Target Groups: payment-api-{blue|green}-{env}

### Shared vs. Per-Service Resources

**Shared (Created Once)**:
- Environments (Dev, Test, Prod)
- Lifecycle (Dev → Test → Prod)
- Project Group (ECS - Canary)

**Per-Service (Created Each Time)**:
- Octopus Project
- Deployment Process (13 inline steps)
- Variables (environment-scoped)
- AWS Resources (ECS, ALB, TGs)

### Current vs. Future Implementation

**Current (In Use)**:
- Inline deployment process
- Defined in: terraform/octopus_deployment_process.tf
- Status: ✅ Fully functional
- Approach: Each service has its own process

**Future (Planned)**:
- Process template approach
- Defined in: .octopus/process-templates/ecs-canary-deployment/
- Status: 🔜 Waiting for provider support
- Approach: Shared process across all services

## Terraform File Relationships

```
terraform.tfvars.example
  ↓ (configure)
terraform/variables.tf
  ↓ (use in)
terraform/locals.tf
  ↓ (reference in)
terraform/octopus_environments.tf    → Creates/queries environments
terraform/octopus_project_group.tf   → Creates/queries project group
terraform/octopus_project.tf         → Creates project
terraform/octopus_deployment_process.tf → Creates 13-step process
terraform/octopus_variables.tf       → Creates variables
terraform/ecs.tf                     → Creates ECS resources
terraform/alb.tf                     → Creates ALB resources
  ↓ (output from)
terraform/outputs.tf
```

## Quick Commands

```bash
# Setup new service
./scripts/setup-microservice.sh my-service

# Initialize Terraform
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate

# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new my-service

# Switch workspace
terraform workspace select my-service
```

## Environment Variables

```bash
# Required for Terraform
export TF_VAR_octopus_api_key="API-XXXXXXXXXX"
export AWS_PROFILE="my-profile"

# Optional AWS credentials
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_REGION="us-east-1"
```

## Common Patterns

### Pattern 1: Single Service
```bash
vim terraform.tfvars    # Set service_name
terraform init
terraform apply
```

### Pattern 2: Multiple Services (Workspaces)
```bash
for service in payment-api user-service order-api; do
  terraform workspace new $service
  terraform workspace select $service
  vim terraform.tfvars  # Set service_name=$service
  terraform apply
done
```

### Pattern 3: Multiple Services (Directories)
```bash
for service in payment-api user-service order-api; do
  ./scripts/setup-microservice.sh $service
  cd .octopus/$service
  vim terraform.tfvars
  terraform init && terraform apply
  cd ../..
done
```

## File Size Reference

| Category | Files | Total Lines |
|----------|-------|-------------|
| Terraform | 12 | ~2,500 |
| Documentation | 8 | ~3,000 |
| Process Templates | 3 | ~800 |
| Scripts | 2 | ~100 |
| **Total** | **25** | **~6,400** |

## Update History

- **Latest**: Inline deployment process implementation
- **Future**: Process template support (when provider adds it)

## Support

- **Issues**: GitHub Issues
- **Community**: Octopus Community Slack
- **Documentation**: https://octopus.com/docs

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Test thoroughly
5. Submit pull request

## License

[Your License]
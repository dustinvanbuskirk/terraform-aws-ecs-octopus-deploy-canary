# ECS Canary Deployment with Octopus Deploy

Deploy microservices to AWS ECS with canary deployments in 5 minutes using ONE variable!

## Quick Start for Developers

```bash
./scripts/setup-microservice.sh my-service
vim .octopus/my-service/terraform.tfvars  # Set service_name + AWS config
cd .octopus/my-service && terraform init && terraform apply
```

## What You Get

Set `service_name = "payment-api"` and automatically get:
- ✅ Octopus Project: payment-api
- ✅ ECS Services: payment-api-dev, payment-api-test, payment-api-prod
- ✅ Load Balancers: payment-api-alb-dev, payment-api-alb-test, payment-api-alb-prod
- ✅ 40+ AWS resources across 3 environments
- ✅ Complete canary deployment process

## Documentation

- **Developers**: Start with docs/developer/DEVELOPER_ONEPAGER.md
- **Platform Team**: See INDEX.md for complete navigation
- **Process Templates**: docs/process-templates/QUICK_REFERENCE.md

## Features

- Progressive canary deployment (10% → 25% → 50% → 100%)
- Blue/Green task sets with zero downtime
- Automated health checks and rollback
- Multi-environment support
- Service name auto-naming
- OCL process templates for Platform Hub

See INDEX.md for complete documentation navigation.

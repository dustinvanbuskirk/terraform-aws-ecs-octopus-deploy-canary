#!/bin/bash
set -e

SERVICE_NAME="${1}"
if [ -z "$SERVICE_NAME" ]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 payment-api"
    exit 1
fi

CONFIG_DIR=".octopus/$SERVICE_NAME"
mkdir -p "$CONFIG_DIR"

cat > "$CONFIG_DIR/terraform.tfvars" << EOF
# Configuration for $SERVICE_NAME

service_name = "$SERVICE_NAME"

vpc_id = "vpc-TODO"
subnet_ids = ["subnet-TODO-1", "subnet-TODO-2"]
security_group_ids = ["sg-TODO"]
alb_subnet_ids = ["subnet-pub-TODO-1", "subnet-pub-TODO-2"]

container_image = "myorg/$SERVICE_NAME"

octopus_server_url = "https://mycompany.octopus.app"
octopus_space_name = "Default"
octopus_lifecycle_id = "Lifecycles-1"
octopus_project_group_id = "ProjectGroups-1"
octopus_aws_account_name = "sales-demo-oidc"
octopus_worker_pool_id = "WorkerPools-64"
EOF

cat > "$CONFIG_DIR/backend.tf" << EOF
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "microservices/$SERVICE_NAME/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
EOF

echo "✓ Created $CONFIG_DIR"
echo ""
echo "Next steps:"
echo "1. Edit: vim $CONFIG_DIR/terraform.tfvars"
echo "2. Update: VPC, subnets, container_image"
echo "3. Deploy: cd $CONFIG_DIR && terraform init && terraform apply"

# Get VPC CIDR for security group rules
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Octopus Deploy Data Sources
data "octopusdeploy_spaces" "example" {
  partial_name = var.octopus_space_name
  take         = 1
}

# Get the AWS OIDC account by name
data "octopusdeploy_accounts" "aws_account" {
  partial_name = var.octopus_aws_account_name
  account_type = "AmazonWebServicesOidcAccount"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

# Try to get existing project
data "octopusdeploy_projects" "existing" {
  partial_name = local.octopus_project_name
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

# Note: Environment and lifecycle data sources removed to eliminate deprecation warnings
# We always create these resources instead of querying for existing ones
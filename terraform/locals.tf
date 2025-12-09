locals {
  # Service naming
  service_name = var.service_name
  task_family  = var.task_family != "" ? var.task_family : var.service_name
  
  # Auto-generate project name from service name if not provided
  octopus_project_name = var.octopus_project_name != "" ? var.octopus_project_name : var.service_name
  
  # Auto-generate environment configurations if not provided
  default_environments = {
    development = {
      name         = "Development"
      service_name = "${var.service_name}-dev"
      alb_name     = "${var.service_name}-alb-dev"
      cluster_name = var.create_ecs_clusters ? "${var.service_name}-cluster-dev" : "${var.cluster_name_prefix}-dev"
    }
    test = {
      name         = "Test"
      service_name = "${var.service_name}-test"
      alb_name     = "${var.service_name}-alb-test"
      cluster_name = var.create_ecs_clusters ? "${var.service_name}-cluster-test" : "${var.cluster_name_prefix}-test"
    }
    production = {
      name         = "Production"
      service_name = "${var.service_name}-prod"
      alb_name     = "${var.service_name}-alb-prod"
      cluster_name = var.create_ecs_clusters ? "${var.service_name}-cluster-prod" : "${var.cluster_name_prefix}-prod"
    }
  }
  
  # Use provided environments or defaults
  environments = length(var.environments) > 0 ? var.environments : local.default_environments
  
  # Octopus Deploy
  octopus_space_id = data.octopusdeploy_spaces.example.spaces[0].id
  
  aws_account_id = length(data.octopusdeploy_accounts.aws_account.accounts) > 0 ? data.octopusdeploy_accounts.aws_account.accounts[0].id : var.octopus_aws_account_name
  
  # Use the environment IDs from octopus_environments.tf (whether created or pre-existing)
  environment_ids = {
    development = local.development_environment_id
    test        = local.test_environment_id
    production  = local.production_environment_id
  }
  
  # lifecycle_id is now defined in octopus_environments.tf
  
  project_exists = length(data.octopusdeploy_projects.existing.projects) > 0
  project_id     = local.project_exists ? data.octopusdeploy_projects.existing.projects[0].id : octopusdeploy_project.ecs_canary[0].id
}
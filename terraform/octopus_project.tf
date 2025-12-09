# Octopus Deploy Project Configuration
# Note: Data source for existing project is in data.tf

resource "octopusdeploy_project" "ecs_canary" {
  count = !local.project_exists ? 1 : 0
  
  name             = local.octopus_project_name
  description      = "ECS Canary deployment for ${var.service_name}"
  lifecycle_id     = local.lifecycle_id
  project_group_id = local.project_group_id
  space_id         = local.octopus_space_id
  
  is_disabled                      = false
  is_version_controlled            = false
  tenanted_deployment_participation = "Untenanted"
  
  connectivity_policy {
    allow_deployments_to_no_targets = true
    exclude_unhealthy_targets        = false
    skip_machine_behavior            = "None"
  }
}
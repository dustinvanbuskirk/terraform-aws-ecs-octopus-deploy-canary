# Create Project Group for ECS Canary Deployments

# ============================================================================
# Data Source - Check if Project Group Already Exists
# ============================================================================

data "octopusdeploy_project_groups" "ecs_canary_check" {
  ids          = null
  partial_name = "ECS - Canary"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

# ============================================================================
# Project Group Resource - Only Create if It Doesn't Exist
# ============================================================================

resource "octopusdeploy_project_group" "ecs_canary" {
  count = length(data.octopusdeploy_project_groups.ecs_canary_check.project_groups) == 0 ? 1 : 0
  
  name        = "ECS - Canary"
  description = "Projects using ECS Canary deployment pattern"
  space_id    = local.octopus_space_id
}

# ============================================================================
# Data Source to Get Project Group ID (Whether Created or Pre-existing)
# ============================================================================

data "octopusdeploy_project_groups" "ecs_canary_selected" {
  ids          = null
  partial_name = "ECS - Canary"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
  
  depends_on = [octopusdeploy_project_group.ecs_canary]
}

# ============================================================================
# Local for Project Group ID
# ============================================================================

locals {
  project_group_id = data.octopusdeploy_project_groups.ecs_canary_selected.project_groups[0].id
}
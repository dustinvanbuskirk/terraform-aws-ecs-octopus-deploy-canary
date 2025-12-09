# Octopus Deploy Environments
# These are created per-space, not per-project

# ============================================================================
# Data Sources - Check if Environments Already Exist
# ============================================================================

data "octopusdeploy_environments" "development_check" {
  ids          = null
  partial_name = "Development"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

data "octopusdeploy_environments" "test_check" {
  ids          = null
  partial_name = "Test"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

data "octopusdeploy_environments" "production_check" {
  ids          = null
  partial_name = "Production"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

# ============================================================================
# Environment Resources - Only Create if They Don't Exist
# ============================================================================

resource "octopusdeploy_environment" "development" {
  count = length(data.octopusdeploy_environments.development_check.environments) == 0 ? 1 : 0
  
  name        = "Development"
  description = "Development environment for all projects"
  space_id    = local.octopus_space_id
  
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
}

resource "octopusdeploy_environment" "test" {
  count = length(data.octopusdeploy_environments.test_check.environments) == 0 ? 1 : 0
  
  name        = "Test"
  description = "Test environment for all projects"
  space_id    = local.octopus_space_id
  
  allow_dynamic_infrastructure = true
  use_guided_failure           = false
}

resource "octopusdeploy_environment" "production" {
  count = length(data.octopusdeploy_environments.production_check.environments) == 0 ? 1 : 0
  
  name        = "Production"
  description = "Production environment for all projects"
  space_id    = local.octopus_space_id
  
  allow_dynamic_infrastructure = false
  use_guided_failure           = true
}

# ============================================================================
# Data Sources to Get Environment IDs (Whether Created or Pre-existing)
# ============================================================================

data "octopusdeploy_environments" "development_selected" {
  ids          = null
  partial_name = "Development"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
  
  depends_on = [octopusdeploy_environment.development]
}

data "octopusdeploy_environments" "test_selected" {
  ids          = null
  partial_name = "Test"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
  
  depends_on = [octopusdeploy_environment.test]
}

data "octopusdeploy_environments" "production_selected" {
  ids          = null
  partial_name = "Production"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
  
  depends_on = [octopusdeploy_environment.production]
}

# ============================================================================
# Locals for Environment IDs
# ============================================================================

locals {
  development_environment_id = data.octopusdeploy_environments.development_selected.environments[0].id
  test_environment_id        = data.octopusdeploy_environments.test_selected.environments[0].id
  production_environment_id  = data.octopusdeploy_environments.production_selected.environments[0].id
}

# ============================================================================
# Standard Lifecycle: Development → Test → Production
# ============================================================================

# Check if lifecycle already exists
data "octopusdeploy_lifecycles" "default_check" {
  ids          = null
  partial_name = "Standard Lifecycle"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
}

resource "octopusdeploy_lifecycle" "default_lifecycle" {
  count = length(data.octopusdeploy_lifecycles.default_check.lifecycles) == 0 ? 1 : 0
  
  name        = "Standard Lifecycle"
  description = "Standard deployment lifecycle: Development → Test → Production"
  space_id    = local.octopus_space_id
  
  # Development phase
  phase {
    name                                  = "Development"
    automatic_deployment_targets          = [local.development_environment_id]
    optional_deployment_targets           = []
    is_optional_phase                     = false
    minimum_environments_before_promotion = 0
  }
  
  # Test phase
  phase {
    name                                  = "Test"
    automatic_deployment_targets          = []
    optional_deployment_targets           = [local.test_environment_id]
    is_optional_phase                     = false
    minimum_environments_before_promotion = 1
  }
  
  # Production phase
  phase {
    name                                  = "Production"
    automatic_deployment_targets          = []
    optional_deployment_targets           = [local.production_environment_id]
    is_optional_phase                     = false
    minimum_environments_before_promotion = 1
  }
  
  # Ensure environments are available
  depends_on = [
    data.octopusdeploy_environments.development_selected,
    data.octopusdeploy_environments.test_selected,
    data.octopusdeploy_environments.production_selected
  ]
}

# Get lifecycle ID (whether created or pre-existing)
data "octopusdeploy_lifecycles" "default_selected" {
  ids          = null
  partial_name = "Standard Lifecycle"
  skip         = 0
  take         = 1
  space_id     = local.octopus_space_id
  
  depends_on = [octopusdeploy_lifecycle.default_lifecycle]
}

# Local for lifecycle ID
locals {
  lifecycle_id = data.octopusdeploy_lifecycles.default_selected.lifecycles[0].id
}
# Project-Level Variables (not environment-specific)

# AWS Account Reference (project-level)
resource "octopusdeploy_variable" "aws_account" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "AWS.Account"
  type        = "AmazonWebServicesAccount"
  value       = local.aws_account_id
  description = "AWS OIDC account for deployments"
}

# Worker Pool Reference (project-level)
resource "octopusdeploy_variable" "worker_pool" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "Worker.Pool"
  type        = "WorkerPool"
  value       = var.octopus_worker_pool_id
  description = "Worker pool for running deployment scripts"
}

# AWS Region (project-level)
resource "octopusdeploy_variable" "aws_region" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "AWS.Region"
  type        = "String"
  value       = var.aws_region
  description = "AWS region for deployments"
}

# ========================================
# Environment-Specific Variables - Development
# ========================================

resource "octopusdeploy_variable" "cluster_arn_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ClusterArn"
  type        = "String"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["development"].arn : var.environments["development"].cluster_name
  description = "ECS Cluster ARN"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "service_name_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ServiceName"
  type        = "String"
  value       = local.environments["development"].service_name
  description = "ECS Service Name"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "blue_target_group_arn_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.BlueTargetGroupArn"
  type        = "String"
  value       = aws_lb_target_group.blue["development"].arn
  description = "Blue Target Group ARN"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "green_target_group_arn_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.GreenTargetGroupArn"
  type        = "String"
  value       = aws_lb_target_group.green["development"].arn
  description = "Green Target Group ARN"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "listener_rule_arn_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ListenerRuleArn"
  type        = "String"
  value       = aws_lb_listener_rule.traffic_split["development"].arn
  description = "Load Balancer Listener Rule ARN for traffic splitting"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "testing_listener_rule_arn_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.TestingListenerRuleArn"
  type        = "String"
  value       = aws_lb_listener_rule.green_testing["development"].arn
  description = "Load Balancer Testing Listener Rule ARN"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "subnet_ids_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.SubnetIds"
  type        = "String"
  value       = join(",", var.subnet_ids)
  description = "Comma-separated list of Subnet IDs for ECS tasks"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

resource "octopusdeploy_variable" "security_group_ids_dev" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.SecurityGroupIds"
  type        = "String"
  value       = join(",", var.security_group_ids)
  description = "Comma-separated list of Security Group IDs for ECS tasks"
  
  scope {
    environments = [local.environment_ids["development"]]
  }
}

# ========================================
# Environment-Specific Variables - Test
# ========================================

resource "octopusdeploy_variable" "cluster_arn_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ClusterArn"
  type        = "String"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["test"].arn : var.environments["test"].cluster_name
  description = "ECS Cluster ARN"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "service_name_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ServiceName"
  type        = "String"
  value       = local.environments["test"].service_name
  description = "ECS Service Name"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "blue_target_group_arn_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.BlueTargetGroupArn"
  type        = "String"
  value       = aws_lb_target_group.blue["test"].arn
  description = "Blue Target Group ARN"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "green_target_group_arn_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.GreenTargetGroupArn"
  type        = "String"
  value       = aws_lb_target_group.green["test"].arn
  description = "Green Target Group ARN"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "listener_rule_arn_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ListenerRuleArn"
  type        = "String"
  value       = aws_lb_listener_rule.traffic_split["test"].arn
  description = "Load Balancer Listener Rule ARN for traffic splitting"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "testing_listener_rule_arn_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.TestingListenerRuleArn"
  type        = "String"
  value       = aws_lb_listener_rule.green_testing["test"].arn
  description = "Load Balancer Testing Listener Rule ARN"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "subnet_ids_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.SubnetIds"
  type        = "String"
  value       = join(",", var.subnet_ids)
  description = "Comma-separated list of Subnet IDs for ECS tasks"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

resource "octopusdeploy_variable" "security_group_ids_test" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.SecurityGroupIds"
  type        = "String"
  value       = join(",", var.security_group_ids)
  description = "Comma-separated list of Security Group IDs for ECS tasks"
  
  scope {
    environments = [local.environment_ids["test"]]
  }
}

# ========================================
# Environment-Specific Variables - Production
# ========================================

resource "octopusdeploy_variable" "cluster_arn_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ClusterArn"
  type        = "String"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["production"].arn : var.environments["production"].cluster_name
  description = "ECS Cluster ARN"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "service_name_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ServiceName"
  type        = "String"
  value       = local.environments["production"].service_name
  description = "ECS Service Name"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "blue_target_group_arn_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.BlueTargetGroupArn"
  type        = "String"
  value       = aws_lb_target_group.blue["production"].arn
  description = "Blue Target Group ARN"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "green_target_group_arn_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.GreenTargetGroupArn"
  type        = "String"
  value       = aws_lb_target_group.green["production"].arn
  description = "Green Target Group ARN"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "listener_rule_arn_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.ListenerRuleArn"
  type        = "String"
  value       = aws_lb_listener_rule.traffic_split["production"].arn
  description = "Load Balancer Listener Rule ARN for traffic splitting"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "testing_listener_rule_arn_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.TestingListenerRuleArn"
  type        = "String"
  value       = aws_lb_listener_rule.green_testing["production"].arn
  description = "Load Balancer Testing Listener Rule ARN"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "subnet_ids_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.SubnetIds"
  type        = "String"
  value       = join(",", var.subnet_ids)
  description = "Comma-separated list of Subnet IDs for ECS tasks"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}

resource "octopusdeploy_variable" "security_group_ids_prod" {
  owner_id    = local.project_id
  space_id    = local.octopus_space_id
  name        = "ECS.SecurityGroupIds"
  type        = "String"
  value       = join(",", var.security_group_ids)
  description = "Comma-separated list of Security Group IDs for ECS tasks"
  
  scope {
    environments = [local.environment_ids["production"]]
  }
}
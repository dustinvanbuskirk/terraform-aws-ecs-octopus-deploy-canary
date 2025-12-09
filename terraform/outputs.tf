# Octopus Deploy Outputs
output "aws_account_id_resolved" {
  description = "Resolved AWS Account ID from name"
  value       = local.aws_account_id
}

output "environment_ids" {
  description = "Map of environment names to IDs"
  value       = local.environment_ids
}

output "octopus_project_id" {
  description = "ID of the Octopus Deploy project"
  value       = local.project_id
}

output "octopus_project_url" {
  description = "URL of the Octopus Deploy project"
  value       = "${var.octopus_server_url}/app#/${local.octopus_space_id}/projects/${local.project_id}"
}

output "octopus_project_exists" {
  description = "Whether the project already existed (true) or was created (false)"
  value       = local.project_exists
}

# ECS Cluster Outputs
output "ecs_cluster_arn_dev" {
  description = "ARN of the Development ECS cluster"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["development"].arn : null
}

output "ecs_cluster_name_dev" {
  description = "Name of the Development ECS cluster"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["development"].name : var.environments["development"].cluster_name
}

output "ecs_cluster_arn_test" {
  description = "ARN of the Test ECS cluster"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["test"].arn : null
}

output "ecs_cluster_name_test" {
  description = "Name of the Test ECS cluster"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["test"].name : var.environments["test"].cluster_name
}

output "ecs_cluster_arn_prod" {
  description = "ARN of the Production ECS cluster"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["production"].arn : null
}

output "ecs_cluster_name_prod" {
  description = "Name of the Production ECS cluster"
  value       = var.create_ecs_clusters ? aws_ecs_cluster.main["production"].name : var.environments["production"].cluster_name
}

# Development Environment Outputs
output "load_balancer_arn_dev" {
  description = "ARN of the Development Application Load Balancer"
  value       = aws_lb.main["development"].arn
}

output "load_balancer_dns_name_dev" {
  description = "DNS name of the Development Application Load Balancer"
  value       = aws_lb.main["development"].dns_name
}

output "load_balancer_url_dev" {
  description = "URL of the Development Application Load Balancer"
  value       = "http://${aws_lb.main["development"].dns_name}"
}

output "testing_url_dev" {
  description = "URL to test Development green deployment directly"
  value       = "http://${aws_lb.main["development"].dns_name}/?test=true"
}

output "blue_target_group_arn_dev" {
  description = "ARN of the Development blue target group"
  value       = aws_lb_target_group.blue["development"].arn
}

output "green_target_group_arn_dev" {
  description = "ARN of the Development green target group"
  value       = aws_lb_target_group.green["development"].arn
}

output "ecs_service_name_dev" {
  description = "Name of the Development ECS service"
  value       = aws_ecs_service.main["development"].name
}

# Test Environment Outputs
output "load_balancer_arn_test" {
  description = "ARN of the Test Application Load Balancer"
  value       = aws_lb.main["test"].arn
}

output "load_balancer_dns_name_test" {
  description = "DNS name of the Test Application Load Balancer"
  value       = aws_lb.main["test"].dns_name
}

output "load_balancer_url_test" {
  description = "URL of the Test Application Load Balancer"
  value       = "http://${aws_lb.main["test"].dns_name}"
}

output "testing_url_test" {
  description = "URL to test Test green deployment directly"
  value       = "http://${aws_lb.main["test"].dns_name}/?test=true"
}

output "blue_target_group_arn_test" {
  description = "ARN of the Test blue target group"
  value       = aws_lb_target_group.blue["test"].arn
}

output "green_target_group_arn_test" {
  description = "ARN of the Test green target group"
  value       = aws_lb_target_group.green["test"].arn
}

output "ecs_service_name_test" {
  description = "Name of the Test ECS service"
  value       = aws_ecs_service.main["test"].name
}

# Production Environment Outputs
output "load_balancer_arn_prod" {
  description = "ARN of the Production Application Load Balancer"
  value       = aws_lb.main["production"].arn
}

output "load_balancer_dns_name_prod" {
  description = "DNS name of the Production Application Load Balancer"
  value       = aws_lb.main["production"].dns_name
}

output "load_balancer_url_prod" {
  description = "URL of the Production Application Load Balancer"
  value       = "http://${aws_lb.main["production"].dns_name}"
}

output "testing_url_prod" {
  description = "URL to test Production green deployment directly"
  value       = "http://${aws_lb.main["production"].dns_name}/?test=true"
}

output "blue_target_group_arn_prod" {
  description = "ARN of the Production blue target group"
  value       = aws_lb_target_group.blue["production"].arn
}

output "green_target_group_arn_prod" {
  description = "ARN of the Production green target group"
  value       = aws_lb_target_group.green["production"].arn
}

output "ecs_service_name_prod" {
  description = "Name of the Production ECS service"
  value       = aws_ecs_service.main["production"].name
}
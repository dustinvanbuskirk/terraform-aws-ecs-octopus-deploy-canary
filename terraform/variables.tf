# AWS Variables
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for task placement"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for tasks"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for the Application Load Balancers (should be public subnets)"
  type        = list(string)
}

variable "alb_security_group_ids" {
  description = "List of security group IDs for the Application Load Balancers (if empty, one will be created per environment)"
  type        = list(string)
  default     = []
}

# ECS Variables
variable "create_ecs_clusters" {
  description = "Whether to create ECS clusters for each environment"
  type        = bool
  default     = true
}

variable "cluster_name_prefix" {
  description = "Prefix for ECS cluster names"
  type        = string
  default     = "ecs-canary-cluster"
}

variable "app_version" {
  description = "Application version environment variable"
  type        = string
  default     = "1.0.0"
}

variable "container_image" {
  description = "Docker container image"
  type        = string
  default     = "octopussamples/helloworldwithversion"
}

variable "task_family" {
  description = "Task definition family name"
  type        = string
  default     = ""
}

# Load Balancer Variables
variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancers"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the load balancers"
  type        = bool
  default     = true
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

# Service Configuration
variable "service_name" {
  description = "Name of the microservice (used for all resource naming)"
  type        = string
}

# Octopus Deploy Variables
variable "octopus_server_url" {
  description = "URL of the Octopus Deploy server"
  type        = string
}

variable "octopus_api_key" {
  description = "API key for Octopus Deploy"
  type        = string
  sensitive   = true
}

variable "octopus_space_name" {
  description = "Octopus Deploy space name"
  type        = string
}

variable "octopus_project_name" {
  description = "Name of the Octopus Deploy project (defaults to service_name if not provided)"
  type        = string
  default     = ""
}

# Note: octopus_project_group_id removed - now created by Terraform
# Note: octopus_process_template_id removed - using inline deployment process

variable "octopus_aws_account_name" {
  description = "Octopus Deploy AWS OIDC account name (e.g., 'sales-demo-oidc')"
  type        = string
  default     = "sales-demo-oidc"
}

variable "octopus_worker_pool_id" {
  description = "Octopus Deploy worker pool ID for running deployment scripts (e.g., 'WorkerPools-64')"
  type        = string
  default     = ""
}

variable "create_deployment_process" {
  description = "Whether to create/update the deployment process (set to true to create for existing projects)"
  type        = bool
  default     = false
}

# Environment Configuration
variable "environments" {
  description = "Map of environment configurations"
  type = map(object({
    name         = string
    service_name = string
    alb_name     = string
    cluster_name = string
  }))
  default = {}
}
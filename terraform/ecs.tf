# ECS Clusters
resource "aws_ecs_cluster" "main" {
  for_each = var.create_ecs_clusters ? local.environments : {}

  name = each.value.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = each.value.cluster_name
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# ECS Cluster Capacity Providers
resource "aws_ecs_cluster_capacity_providers" "main" {
  for_each = var.create_ecs_clusters ? local.environments : {}

  cluster_name = aws_ecs_cluster.main[each.key].name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# ECS Task Definitions (one per environment)
resource "aws_ecs_task_definition" "main" {
  for_each = local.environments

  family                   = "${local.task_family}-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "mycontainer"
      image     = "${var.container_image}:latest"
      cpu       = 256
      memory    = 512
      memoryReservation = 128
      essential = true
      
      environment = [
        {
          name  = "APPVERSION"
          value = var.app_version
        },
        {
          name  = "ENVIRONMENT"
          value = each.value.name
        },
        {
          name  = "SERVICE_NAME"
          value = local.service_name
        }
      ]
      
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name        = "${local.task_family}-${each.key}"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# ECS Services with External Deployment Controller
resource "aws_ecs_service" "main" {
  for_each = local.environments

  name            = each.value.service_name
  cluster         = var.create_ecs_clusters ? aws_ecs_cluster.main[each.key].arn : each.value.cluster_name
  desired_count   = 1
  launch_type     = "FARGATE"

  deployment_controller {
    type = "EXTERNAL"
  }

  tags = {
    StableStack = "Blue"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
      load_balancer
    ]
  }
}

# Blue Task Sets
resource "aws_ecs_task_set" "blue" {
  for_each = local.environments

  service         = aws_ecs_service.main[each.key].id
  cluster         = var.create_ecs_clusters ? aws_ecs_cluster.main[each.key].arn : each.value.cluster_name
  task_definition = aws_ecs_task_definition.main[each.key].arn
  external_id     = "OctopusBlueStack"

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.blue[each.key].arn
    container_name   = "mycontainer"
    container_port   = 4000
  }

  scale {
    unit  = "PERCENT"
    value = 100
  }

  tags = {
    Stack       = "Blue"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}

# Green Task Sets
resource "aws_ecs_task_set" "green" {
  for_each = local.environments

  service         = aws_ecs_service.main[each.key].id
  cluster         = var.create_ecs_clusters ? aws_ecs_cluster.main[each.key].arn : each.value.cluster_name
  task_definition = aws_ecs_task_definition.main[each.key].arn
  external_id     = "OctopusGreenStack"

  launch_type = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.green[each.key].arn
    container_name   = "mycontainer"
    container_port   = 4000
  }

  scale {
    unit  = "PERCENT"
    value = 100
  }

  tags = {
    Stack       = "Green"
    Environment = each.value.name
    Service     = local.service_name
    ManagedBy   = "Terraform"
  }
}
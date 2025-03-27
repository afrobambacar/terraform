# Shared resources
data "aws_vpc" "selected" {
  tags = {
    Name = var.vpc_name
  }
}

data "aws_subnets" "selected" {
  tags = {
    Name = var.subnet_names
  }
}

data "aws_route53_zone" "public" {
  name         = var.route53_zone_name
  private_zone = var.route53_private_zone
}

data "aws_lb" "internet_facing" {
  name = var.elb_name
}

data "aws_lb_listener" "https" {
  load_balancer_arn = data.aws_lb.internet_facing.arn
  port              = 443
}

data "aws_security_groups" "selected" {
  filter {
    name   = "group-name"
    values = var.security_group_name
  }
}

data "aws_iam_role" "ecs_task_role" {
  name = var.ecs_task_role_name
}

data "aws_iam_role" "task_execution_role" {
  name = var.task_excution_role_name
}

# Create log group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.ecs_task_definition_container}"
  retention_in_days = var.stage == "main" ? 30 : 7

  tags = {
    Environment = var.stage
    Application = var.project_name
  }
}

# Create Target Group & link to ALB
resource "aws_route53_record" "public" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = var.route53_record
  type    = "A"

  alias {
    name                   = data.aws_lb.internet_facing.dns_name
    zone_id                = data.aws_lb.internet_facing.zone_id
    evaluate_target_health = true
  }
}

resource "aws_lb_target_group" "this" {
  vpc_id      = data.aws_vpc.selected.id
  name        = var.target_group
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = data.aws_lb_listener.https.arn
  priority     = null

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    host_header {
      values = [var.route53_record]
    }
  }
}

# ECR
resource "aws_ecr_repository" "this" {
  name                 = var.ecr_repository
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Keep image deployed with tag latest",
        "selection": {
          "tagStatus": "tagged",
          "tagPrefixList": ["latest"],
          "countType": "imageCountMoreThan",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      },
      {
        "rulePriority": 2,
        "description": "Keep last 2 any images",
        "selection": {
          "tagStatus": "any",
          "countType": "imageCountMoreThan",
          "countNumber": 2
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}

# ECS admin-stage task-definition, service and cluster
resource "aws_ecs_task_definition" "this" {
  family                   = var.ecs_task_definition_family
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.task_execution_role.arn
  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = var.ecs_task_definition_container
      image     = "public.ecr.aws/nginx/nginx:1.27-alpine3.21-slim"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          protocol      = "tcp"
          hostPort      = var.host_port
          containerPort = var.container_port
        }
      ]
    }
  ])
}

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster
}

resource "aws_ecs_service" "this" {
  name                 = var.ecs_service
  cluster              = aws_ecs_cluster.this.id
  task_definition      = aws_ecs_task_definition.this.arn
  desired_count        = 1
  force_new_deployment = false
  launch_type          = "FARGATE"

  network_configuration {
    security_groups  = data.aws_security_groups.selected.ids
    subnets          = data.aws_subnets.selected.ids
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.ecs_task_definition_container
    container_port   = var.container_port
  }

  depends_on = [
    aws_ecr_repository.this,
    aws_ecs_task_definition.this,
    aws_cloudwatch_log_group.this,
    aws_lb_listener_rule.this,
  ]

  lifecycle {
    ignore_changes = [task_definition]
  }
}

resource "aws_appautoscaling_target" "this" {
  max_capacity       = 10
  min_capacity       = 1
  resource_id        = "service/${var.ecs_cluster}/${var.ecs_service}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "memory" {
  name               = "dev-to-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "dev-to-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this.resource_id
  scalable_dimension = aws_appautoscaling_target.this.scalable_dimension
  service_namespace  = aws_appautoscaling_target.this.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}

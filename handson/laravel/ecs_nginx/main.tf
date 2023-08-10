variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "https_listener_arn" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

locals {
  name = "${var.name}-nginx"
}

resource "aws_lb_target_group" "this" {
  name = local.name

  vpc_id = var.vpc_id

  port        = 80
  target_type = "ip"
  protocol    = "HTTP"

  health_check = {
    port = 80
  }
}

data "template_file" "container_definitions" {
  template = file("./ecs_nginx/container_definitions.json")
}

resource "aws_ecs_task_definition" "this" {
  family = local.name

  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = data.template_file.container_definitions.rendered
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.https_listener_arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.id
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_security_group" "this" {
  name        = local.name
  description = local.name

  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
}

resource "aws_security_group_rule" "this_http" {
  security_group_id = aws_security_group.this.id

  type = "ingress"

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_ecs_service" "this" {
  depends_on = [aws_lb_listener_rule.this]

  name = local.name

  launch_type = "FARGATE"

  desired_count = 1

  cluster = var.cluster_name

  task_definition = aws_ecs_task_definition.this.arn

  network_configuration = {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.this.id]
  }

  load_balancer = [
    {
      target_group_arn = aws_lb_target_group.this.arn
      container_name   = "nginx"
      container_port   = "80"
    },
  ]
}

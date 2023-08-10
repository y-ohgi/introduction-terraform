variable "name" {
  type = string
}

resource "aws_ecs_cluster" "this" {
  name = var.name
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

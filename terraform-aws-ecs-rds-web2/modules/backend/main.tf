# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "flask-app-repo"
  force_delete         = true
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "flask-app-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}
variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "route_table_ids" {
  type = list(string)
}

variable "db_host" {
  type = string
}

variable "db_name" {
  type = string
}

variable "db_user" {
  type = string
}

variable "db_password" {
  type = string
  description = "Secrets Manager ARN for DB password"
}

variable "ecs_execution_role_arn" {
  type = string
}
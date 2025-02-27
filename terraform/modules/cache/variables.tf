variable "project_name" {
  description = "Name of the project, used in resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where Redis will be placed"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for Redis"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
}

variable "port" {
  description = "Port number for Redis"
  type        = number
  default     = 6379
}

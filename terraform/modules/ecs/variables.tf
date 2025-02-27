variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for the ECS tasks"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for ECS instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for ECS instances"
  type        = string
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
}

variable "container_image" {
  description = "Docker image for the application container"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "container_cpu" {
  description = "CPU units for the container"
  type        = number
}

variable "container_memory" {
  description = "Memory for the container in MiB"
  type        = number
}

variable "database_url_secret_arn" {
  description = "ARN of the database URL secret in Secrets Manager"
  type        = string
}

variable "rails_master_key_secret_arn" {
  description = "ARN of the Rails master key secret in Secrets Manager"
  type        = string
}

variable "redis_url" {
  description = "Redis URL for the application"
  type        = string
}

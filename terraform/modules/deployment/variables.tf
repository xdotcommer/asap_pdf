variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The environment (e.g., production, staging)"
  type        = string
}

variable "github_repository" {
  description = "The GitHub repository in format owner/repo"
  type        = string
}

variable "db_username" {
  description = "The database username"
  type        = string
}

variable "db_password_secret_arn" {
  description = "The ARN of the secret containing the database password"
  type        = string
}

variable "db_endpoint" {
  description = "The database endpoint"
  type        = string
}

variable "db_name" {
  description = "The database name"
  type        = string
}

variable "rails_master_key" {
  description = "The Rails master key for the application"
  type        = string
  sensitive   = true
  default     = null
}

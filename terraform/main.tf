# Data source for latest Amazon ECS-optimized AMI
data "aws_ami" "ecs" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Networking
module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = ["us-east-1a", "us-east-1b"]
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Database
module "database" {
  source = "./modules/database"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.rds_security_group_id
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  db_username       = var.db_username
}

# Redis for Sidekiq
module "cache" {
  source = "./modules/cache"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.redis_security_group_id
  node_type         = var.redis_node_type
  port              = var.redis_port
}

# Deployment resources (ECR, GitHub Actions, Secrets)
module "deployment" {
  source = "./modules/deployment"

  project_name      = var.project_name
  environment       = var.environment
  github_repository = var.github_repository

  db_username            = var.db_username
  db_password_secret_arn = module.database.db_password_secret_arn
  db_endpoint            = module.database.db_instance_endpoint
  db_name                = var.db_name
  rails_master_key       = var.rails_master_key
  aws_account_id         = var.aws_account_id
}

# ECS
module "ecs" {
  source = "./modules/ecs"

  project_name      = var.project_name
  environment       = var.environment
  subnet_ids        = module.networking.public_subnet_ids
  security_group_id = module.networking.ecs_security_group_id
  ami_id            = data.aws_ami.ecs.id
  instance_type     = var.ecs_instance_type
  min_size          = var.ecs_min_size
  max_size          = var.ecs_max_size

  container_image  = "${module.deployment.ecr_repository_url}:latest"
  container_port   = var.container_port
  container_cpu    = var.container_cpu
  container_memory = var.container_memory

  database_url_secret_arn     = module.deployment.database_url_secret_arn
  rails_master_key_secret_arn = module.deployment.rails_master_key_secret_arn

  redis_url = format("redis://%s:%s",
    module.cache.redis_endpoint,
    module.cache.redis_port
  )
}

# S3 bucket for PDF storage
resource "aws_s3_bucket" "documents" {
  bucket = "${var.project_name}-${var.environment}-documents"

  tags = {
    Name        = "${var.project_name}-${var.environment}-documents"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "documents" {
  bucket = aws_s3_bucket.documents.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "documents" {
  bucket = aws_s3_bucket.documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# IAM policy for ECS tasks to access S3
resource "aws_iam_role_policy" "ecs_s3_access" {
  name = "${var.project_name}-${var.environment}-ecs-s3-access"
  role = split("/", module.ecs.task_execution_role_arn)[1]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.documents.arn,
          "${aws_s3_bucket.documents.arn}/*"
        ]
      }
    ]
  })
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "${var.project_name}-${var.environment}"
  force_delete         = true
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Environment = var.environment
  }
}

# GitHub OIDC Provider
# https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1", # GitHub's OIDC thumbprint
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"  # GitHub's OIDC v2 thumbprint
  ]

  tags = {
    Name = "github-actions"
  }
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:${var.github_repository}:*",
              "repo:${var.github_repository}:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-github-actions"
    Environment = var.environment
  }
}

# IAM Policy for GitHub Actions
resource "aws_iam_role_policy" "github_actions" {
  name = "${var.project_name}-${var.environment}-github-actions"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:RegisterTaskDefinition",
          "ecs:ListTaskDefinitions",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:GetLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/ecs/${var.project_name}-${var.environment}:*"
      },
      {
        Effect = "Allow"
        Action = "iam:PassRole"
        Resource = [
          "arn:aws:iam::${var.aws_account_id}:role/${var.project_name}-${var.environment}-task-execution-role"
        ]
      }
    ]
  })
}

# Database URL Secret
resource "aws_secretsmanager_secret" "database_url" {
  name = "${var.project_name}/${var.environment}/DATABASE_URL"

  tags = {
    Name        = "${var.project_name}-${var.environment}-database-url"
    Environment = var.environment
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

resource "aws_secretsmanager_secret_version" "database_url" {
  secret_id = aws_secretsmanager_secret.database_url.id
  secret_string = format("postgres://%s:%s@%s/%s",
    var.db_username,
    data.aws_secretsmanager_secret_version.db_password.secret_string,
    var.db_endpoint,
    var.db_name
  )
}

# Rails Master Key Secret
resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${var.project_name}/${var.environment}/RAILS_MASTER_KEY"

  tags = {
    Name        = "${var.project_name}-${var.environment}-rails-master-key"
    Environment = var.environment
  }
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_string = var.rails_master_key
}

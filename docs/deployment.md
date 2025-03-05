# Deployment Guide

This application is deployed to AWS ECS using GitHub Actions. Here's how to set up and manage deployments.

## Prerequisites

1. **Terraform Configuration**
   - Update terraform.tfvars with your GitHub repository:
     ```hcl
     github_repository = "codeforamerica/asap_pdf"
     ```
   - Set your Rails master key:
     ```hcl
     rails_master_key = "your-rails-master-key"
     ```

2. **GitHub Repository Setup**
   - Configure GitHub Environment `production`
   - Add repository secrets:
     - `RAILS_MASTER_KEY` (same as in terraform.tfvars)

3. **Infrastructure Deployment**
   - Run Terraform to set up:
     - ECR repository
     - ECS cluster and service
     - GitHub Actions OIDC provider and role
     - AWS Secrets Manager secrets
     ```bash
     tofu init
     tofu plan
     tofu apply
     ```

## Deployment Process

1. **Manual Deployment**
   - Push changes to the `main` branch
   - GitHub Actions will automatically:
     - Build the Docker image
     - Push to ECR
     - Update ECS task definition
     - Deploy to ECS service

2. **Monitoring Deployments**
   - Check GitHub Actions tab for deployment status
   - Monitor ECS service events in AWS Console
   - View application logs in CloudWatch

## Health Checks

The application uses Rails' built-in health check endpoint at `/up` for container health monitoring. This endpoint is provided by Rails and automatically checks the application's basic functionality, including database connectivity.

The ECS task definition includes a health check configuration that:
- Calls the `/up` endpoint every 30 seconds
- Times out after 5 seconds
- Retries 3 times before marking unhealthy
- Allows 60 seconds startup time for initial health check

## Infrastructure

- **ECS Service**: `asap-pdf-production-service`
- **Task Definition**: Located in `.aws/task-definition.json`
- **Container**: Runs on port 80
- **Logs**: Available in CloudWatch group `/ecs/asap-pdf-production`

## Rollback Process

To rollback to a previous version:

1. Find the desired task definition revision in AWS Console
2. Update the ECS service to use that revision:
   ```bash
   aws ecs update-service \
     --cluster asap-pdf-production \
     --service asap-pdf-production-service \
     --task-definition asap-pdf-production:<REVISION_NUMBER>
   ```

## Common Issues

1. **Health Check Failures**
   - Verify the application is binding to port 80
   - Check CloudWatch logs for application errors
   - Ensure database migrations have run successfully

2. **Memory Issues**
   - Monitor CloudWatch metrics
   - Consider adjusting task definition memory limits if needed

3. **Database Connection Issues**
   - Verify security group settings
   - Check DATABASE_URL secret in AWS Secrets Manager
   - Ensure RDS instance is running and accessible

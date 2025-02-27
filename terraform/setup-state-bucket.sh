#!/bin/bash

# Set AWS Profile
export AWS_PROFILE="cfa-ai-studio"

# Configuration
BUCKET_NAME="asap-pdf-terraform-state"
REGION="us-east-1"

# Create the S3 bucket
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'

echo "Terraform state bucket '$BUCKET_NAME' has been created and configured."

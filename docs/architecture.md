# PDF Processing Pipeline Architecture

## Overview

This document outlines the architecture of the PDF processing pipeline, including the integrated Python components, AWS services, and other infrastructure elements.

## System Architecture

### Components

1. **Rails Application**:
   - Serves as the backbone of the system
   - Manages user authentication and document management
   - Provides API endpoints for Python components
   - Runs on AWS Fargate
   - Uses RDS for database storage
   - Uses Elasticache (Redis) for background job queuing

2. **Python Components** (Located in python_components/):
   - **Site Crawler**: Crawls government websites to identify PDF files
   - **Metadata Downloader**: Downloads PDF files and extracts metadata
   - **Document Classifier**: Uses an LLM to determine the document "type"
   - **Policy Reviewer**: Reviews document content against WCAG 2.1 Accessibility Policy
   - **Document Transformer**: Extracts and transforms PDF content into MD or HTML

3. **AWS Infrastructure**:
   - **S3**: Stores versioned PDF files and other assets
     - Uses bucket versioning for document history
     - Organizes files by site and document ID
     - Maintains complete version history of all documents
   - **Lambda**: Runs Python components
   - **RDS**: Manages the Rails application database
   - **Fargate**: Runs the Rails application
   - **Elasticache (Redis)**: Manages background jobs and job queuing

## Document Storage and Versioning

### S3 Storage Structure

Documents are stored in S3 using a hierarchical structure:
```
cfa-aistudio-asap-pdf/                 # Bucket
├── www-city-org/                      # Site prefix (from primary_url)
│   ├── 123/                           # Document ID
│   │   └── document.pdf               # PDF file (versioned)
│   └── 456/
│       └── document.pdf
└── www-othercity-gov/
    └── 789/
        └── document.pdf
```

### Version Management

The system uses S3 versioning to track document changes over time:

1. **Automatic Versioning**:
   - Every file update creates a new version automatically
   - S3 maintains complete version history
   - No explicit version management needed in application code

2. **Version Access**:
   - Latest version always available at the main path
   - Previous versions accessible by version ID
   - Full version history available through S3 API

3. **Document Model Integration**:
   ```ruby
   document.s3_path             # Get full S3 path
   document.latest_file         # Get current version
   document.file_versions       # List all versions
   document.file_version(id)    # Get specific version
   document.version_metadata(v) # Get version metadata
   ```

4. **Version Metadata**:
   - Version ID
   - Last modified timestamp
   - File size
   - ETag for change detection

### Development Environment

LocalStack provides S3 versioning support in development:
- Automatically creates versioned bucket
- Matches production S3 behavior
- Enables local testing of version management

4. **Background Processing**:
   - **Sidekiq**: Manages background jobs in the Rails application
   - **Redis**: Provides job queuing and caching capabilities

## Project Structure

```
rails_app/
├── app/                    # Rails application code
├── config/                # Rails configuration
├── python_components/     # Python processing components
│   ├── document_classifier/
│   ├── document_transformer/
│   ├── metadata_downloader/
│   ├── policy_reviewer/
│   └── site_crawler/
├── spec/
│   └── integration/      # End-to-end tests
├── docker/
│   ├── Dockerfile.rails  # Rails application container
│   └── Dockerfile.python # Python components container
└── docker-compose.yml    # Local development setup
```

## Integration Flow

1. **Document Discovery**:
   - Site Crawler component identifies PDFs on government websites
   - Sends document metadata to Rails API
   - Rails app creates document records and queues download jobs

2. **Document Processing**:
   - Metadata Downloader component downloads PDFs to S3
   - Document Classifier component analyzes and categorizes documents
   - Policy Reviewer component checks WCAG 2.1 compliance
   - Document Transformer component converts PDFs to MD/HTML as needed

3. **Data Storage**:
   - PDF files stored in S3
   - Document metadata and relationships stored in RDS
   - Processing status tracked in document workflow history

## Local Development

The entire system can be run locally using:
```bash
docker-compose up
```

This will start:
- Rails application
- Python components
- Redis for background jobs
- Local development database

## API Integration

The Rails application provides RESTful API endpoints for:
- Document creation and updates
- Processing status updates
- Workflow history tracking
- Document metadata management

## Reference Diagrams

### System Architecture
See [asap-system-architecture.png](asap-system-architecture.png) for a visual representation of the system architecture.

### Sequence Diagram
See [asap-sequence-diagram.png](asap-sequence-diagram.png) for the detailed processing flow.

# ASAP PDF

A Rails application for monitoring websites and automating the remediation of and accessibility of PDF files.

## Prerequisites

Before you begin, ensure you have the following installed:

* Ruby 3.3.4 (we recommend using a version manager like `rbenv` or `rvm`)
* Node.js 23.4.0 (we recommend using `nvm` for version management)
* Yarn (latest version)
* Redis (for Sidekiq background jobs)
* SQLite3 (default database)
* Docker and Docker Compose (for LocalStack S3 in development)

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/xdotcommer/asap_pdf.git
   cd asap_pdf
   ```

2. Install Ruby dependencies:
   ```bash
   bundle install
   ```

3. Install JavaScript dependencies:
   ```bash
   yarn install
   ```

4. Setup the database:
   ```bash
   bin/rails db:setup
   ```

## Running the Application

Start the development server and all required processes:
```bash
bin/dev
```

This command starts the following processes (defined in `Procfile.dev`):
- Rails server
- JavaScript build process (with esbuild)
- CSS build process (with Tailwind CSS)
- Sidekiq worker for background jobs

The application will be available at http://localhost:3000

## Architecture Overview

- **Frontend**: Built with Hotwired (Turbo + Stimulus) and Tailwind CSS
- **Backend**: Ruby on Rails 8.0
- **Background Jobs**: Sidekiq with Redis
- **Testing**: RSpec

## Background Jobs

Background jobs are processed using Sidekiq. The Redis server must be running for Sidekiq to work. Jobs are configured in the following queues (in order of priority):
- critical
- default
- low
- mailers

Example of creating a background job:
```ruby
# app/jobs/example_job.rb
ExampleJob.perform_later("argument")
```

## Testing

Run the test suite:
```bash
bundle exec rails test:prepare
bundle exec rspec
```

## Development Tools

The project includes several development tools:

- **Brakeman**: Security analysis (`bin/brakeman`)
- **RuboCop**: Code style checking (`bin/rubocop`)
- **Overcommit**: Git hooks management
- **Better Errors**: Enhanced error pages in development
- **Bullet**: N+1 query detection

## Environment Variables

The following environment variables can be configured:

- `REDIS_URL`: Redis connection URL (default: redis://localhost:6379/0)
- `AWS_ACCESS_KEY_ID`: AWS access key for S3 in production
- `AWS_SECRET_ACCESS_KEY`: AWS secret key for S3 in production

## API Documentation

The application provides a RESTful API using Grape. API documentation is available through Swagger UI.

### Accessing the API Documentation

Once the application is running:
1. Visit http://localhost:3000/api-docs to access the Swagger UI
2. Browse and test the available endpoints directly in your browser

### Available Endpoints

#### Sites API (v1)

- `GET /api/v1/sites`
  - Lists all sites
  - Returns site details excluding user_id, created_at, updated_at
  - Includes s3_endpoint for each site

- `GET /api/v1/sites/:id`
  - Retrieves a specific site
  - Returns site details excluding user_id, created_at, updated_at
  - Includes s3_endpoint

## Document Storage

The application uses S3 with automatic versioning to track document changes over time. This allows us to maintain a complete history of each document as it changes externally (e.g., when a city updates their PDF) or internally (e.g., after accessibility improvements).

See [architecture.md](docs/architecture.md#document-storage-and-versioning) for detailed documentation of the storage system.

### Quick Start

1. **Development Setup**:
   ```bash
   docker-compose up
   ```
   This starts LocalStack with S3 versioning enabled, matching production behavior.

2. **Production Setup**:
   ```bash
   # Create and configure S3 bucket
   aws s3 mb s3://cfa-aistudio-asap-pdf
   aws s3api put-bucket-versioning \
     --bucket cfa-aistudio-asap-pdf \
     --versioning-configuration Status=Enabled

   # Configure credentials
   EDITOR="code --wait" bin/rails credentials:edit
   ```
   Add to credentials:
   ```yaml
   aws:
     access_key_id: your_access_key_here
     secret_access_key: your_secret_key_here
   ```

3. **S3 Path Structure**:
   The application uses a standardized S3 path structure for all documents:
   ```ruby
   # Global S3 bucket
   S3_BUCKET = "s3://cfa-aistudio-asap-pdf"

   # Site-specific paths
   site.s3_endpoint          # Returns "s3://cfa-aistudio-asap-pdf/site-url-host"
   site.s3_endpoint_prefix   # Returns "site-url-host" (sanitized hostname)
   site.s3_key_for("file")  # Returns "site-url-host/file"
   ```
   Each site gets its own prefix based on its primary URL's hostname, ensuring
   unique and organized storage paths.

4. **Working with Versions**:
   ```ruby
   # Get document versions
   document.latest_file          # Most recent version
   document.file_versions        # All versions
   document.file_version(id)     # Specific version

   # Get version details
   version = document.latest_file
   document.version_metadata(version)  # Version metadata
   ```

The system automatically maintains version history as files change, with no additional configuration needed. Each document has its own path in S3 based on its site's URL and document ID.

## Contributing

1. Ensure all tests pass and no new RuboCop violations are introduced
2. Update documentation as needed
3. Follow the existing code style and conventions

## License

This project is licensed under CC0 1.0 Universal. See the [LICENSE](LICENSE) file for details.

# Access PDF UI

A Rails application for managing and accessing PDF documents.

## Prerequisites

Before you begin, ensure you have the following installed:

* Ruby 3.3.4 (we recommend using a version manager like `rbenv` or `rvm`)
* Node.js 23.4.0 (we recommend using `nvm` for version management)
* Yarn (latest version)
* Redis (for Sidekiq background jobs)
* SQLite3 (default database)

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/xdotcommer/access_pdf_ui.git
   cd access_pdf_ui
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
rails test:prepare
bundle exec bin/rspec
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

## Contributing

1. Ensure all tests pass and no new RuboCop violations are introduced
2. Update documentation as needed
3. Follow the existing code style and conventions

## License

This project is licensed under CC0 1.0 Universal. See the [LICENSE](LICENSE) file for details.

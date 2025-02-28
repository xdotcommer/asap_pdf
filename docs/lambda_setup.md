# Setting Up the Document Summarization Lambda

The document summarization feature uses a local Lambda function that leverages Google's Gemini Pro model to generate summaries of PDF documents. This guide explains how to set up and run the Lambda function locally.

## Prerequisites

- Python 3.10+
- Docker and Docker Compose (for LocalStack)
- Google Cloud account with access to Gemini API
- Gemini API key

## Configuration

1. Create a `config.json` file in the `python_components/summary` directory:

```json
{
  "active_model": "gemini-1.5-pro-latest",
  "key": "your-gemini-api-key",
  "page_limit": 7,
  "prompt": "The following images show a local government document. Could you summarize the contents in two or three sentences?"
}
```

Replace `your-gemini-api-key` with your actual Gemini API key from the Google Cloud Console.

## Setup Steps

1. Start LocalStack (required for AWS services simulation):
   ```bash
   docker-compose up
   ```

2. Run the setup script to store the API keys in LocalStack:
   ```bash
   bin/setup_python_components
   ```
   When prompted, enter your Gemini API key.

## Testing the Setup

1. The Lambda function should now be running at `http://localhost:9000`
2. In the application, click on a document to open the modal
3. Click the "Summarize Document" button
4. The Lambda function will process the PDF and return a summary

## Troubleshooting

If the summarize button doesn't work:

1. Check that LocalStack is running:
   ```bash
   docker ps
   ```
   You should see a LocalStack container running.

2. Verify the Lambda function is running:
   ```bash
   curl http://localhost:9000
   ```
   You should get a response.

3. Check the browser console for any error messages.

4. Verify your Gemini API key is valid and has been properly stored in LocalStack.

## Architecture

The summarization process works as follows:

1. When the "Summarize" button is clicked, the Rails application sends a request to the Lambda function
2. The Lambda function:
   - Downloads the PDF
   - Converts pages to images (up to the configured page limit)
   - Sends the images to the Gemini API for analysis
   - Returns the generated summary
3. The summary is stored in the database and displayed in the UI

## Environment Variables

The Lambda function uses the following environment variables:

- `ASAP_LOCAL_MODE`: Set to `true` for local development (default: `false`)
- `AWS_ACCESS_KEY_ID`: AWS access key (handled by LocalStack in development)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (handled by LocalStack in development)
- `AWS_REGION`: AWS region (default: `us-east-1`)

## Models

The system supports the following models:

- `gemini-1.5-pro-latest`: Google's Gemini Pro model (default)
- `anthropic/claude-3-5-haiku-latest`: Anthropic's Claude model (alternative option)

The active model can be configured in `config.json`.

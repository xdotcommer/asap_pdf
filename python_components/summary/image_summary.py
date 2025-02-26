import argparse
import re
import time

import llm
from dotenv import load_dotenv

from experiment import get_attachments_for_prompt, get_default_args, logger

"""
Utility script for evaluating document summarization via image analysis.
"""

load_dotenv()

models = [
    # LLava requires running ollama server with docker compose.
    'llava:latest',
    # The following models leverage APIs directly via LLM plugins.
    'anthropic/claude-3-opus-latest',
    'anthropic/claude-3-5-haiku-latest',
    'gemini-1.5-pro-latest',
]


def run_experiment(args: argparse.Namespace) -> None:
    """
    Iterates over the list of models and gets them to summarize documents via collection of images.

    Parameters
    ----------
    args: argparse.Namespace
      Arguments parsed from the command line.
    """
    attachments = get_attachments_for_prompt(args.input_directory)
    logger.info(f'Found {len(attachments)} images to summarize in {args.input_directory}.')
    for model_name in models:
        logger.info(f'Summarizing with {model_name}...')
        model = llm.get_model(model_name)
        start = time.time()
        if args.mode == 'summary':
            response = model.prompt(
                "The following images show a local government document. Could you summarize the contents in two or three sentences?",
                attachments=attachments
            )
        if args.mode == 'to_html':
            response = model.prompt(
                "The following images show a local government document. Could you convert the contents to HTML?",
                attachments=attachments
            )
        summary = response.text()
        duration = time.time() - start
        logger.info(f'Inference took {duration} seconds.')
        filename = re.sub(r'[^a-zA-Z0-9]', '_', model_name)
        if args.mode == 'summary':
            filename = f'{filename}_image_summary.txt'
        if args.mode == 'to_html':
            filename = f'{filename}_html_conversion.html'
        with open(f'{args.output_directory}/{filename}', "w") as file:
            file.write(summary)
    logger.info('All done!')


if __name__ == '__main__':
    parser = get_default_args('Asks several LLMs to summarize images representing a document.')
    parser.add_argument('--mode', default='summary', choices=['summary', 'to_html'],
                        help='Ask our friends to either perform a "summary" or convert images "to_html".')
    run_experiment(parser.parse_args())

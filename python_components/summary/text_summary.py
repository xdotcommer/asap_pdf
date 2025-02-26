import argparse
import re
import time

import llm
import tiktoken
from dotenv import load_dotenv

from experiment import get_default_args, get_text_for_prompt, logger

load_dotenv()

models = [
    # LLama3 requires running ollama server with docker compose.
    'llama3:latest',
    # The following models leverage APIs directly via LLM plugins.
    'command-r-plus',
    'command-r',
    'gemini-1.5-pro-latest',
    'anthropic/claude-3-opus-latest'
]

"""
Utility script for evaluating document summarization via image analysis.
"""

def run_experiment(args: argparse.Namespace):
    """
    Iterates over the list of models and gets them to summarize documents from text.

    Parameters
    ----------
    args: argparse.Namespace
      Arguments parsed from the command line.
    """
    logger.info('Loading input text.')
    input_text = get_text_for_prompt(args.input_directory)
    encoding = tiktoken.encoding_for_model("gpt-4o-mini")
    token_count = len(encoding.encode(input_text))
    logger.info(f'Input text from {args.input_directory} has {token_count} tokens.')
    for model_name in models:
        logger.info(f'Summarizing with {model_name}...')
        model = llm.get_model(model_name)
        prompt = f'''
        Could you please summarize in two or three sentences the following content from a local government website?
        {input_text}
        '''
        start = time.time()
        response = model.prompt(prompt)
        summary = response.text()
        duration = time.time() - start
        logger.info(f'Inference took {duration} seconds.')
        filename = re.sub(r'[^a-zA-Z0-9]', '_', model_name)
        with open(f'{args.output_directory}/{filename}_text_summary.txt', "w") as file:
            file.write(summary)
    logger.info('All done!')

if __name__ == '__main__':
    parser = get_default_args('Asks several LLMs to summarize text content of a document.')
    run_experiment(parser.parse_args())
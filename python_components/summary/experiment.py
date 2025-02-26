import argparse
import logging
import math
import os
import pathlib
import re
from glob import glob

import llm
import pdf2image

"""
Some very simple utilities for running experiments.
"""

# Create and provide a very simple logger implementation.
logger = logging.getLogger('experiment_utility')
formatter = logging.Formatter('%(asctime)s: %(message)s')
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter(formatter)
logger.addHandler(ch)

# A regex for extracting numbers from filenames.
file_pattern = re.compile(r'.*?(\d+).*?')


def get_text_for_prompt(path: str, **kwargs) -> str:
    """
    Reads and concatenates text files from a directory within a specified page range.

    Parameters
    ----------
    path : str
        The directory path containing text files.
    **kwargs
        Optional keyword arguments:
        start_page : int, optional
            The starting page index (default: 0).
        stop_page : int, optional
            The ending page index (inclusive, default: None).

    Returns
    -------
    str
        The concatenated text from the specified text files.

    Raises
    ------
    RuntimeError
        If the provided path does not contain any text files.
    """
    start = kwargs.get('start_page', 0)
    end = kwargs.get('stop_page', None)
    text_to_summarize = ''
    path = path.rstrip('/')
    i = None
    for i, filepath in enumerate(sorted(glob(f'{path}/*.txt'), key=_get_order)):
        if i < start or (end is not None and i > end):
            break
        with open(filepath, 'r') as file:
            text_to_summarize += file.read()
    if i is None:
        raise RuntimeError(f'Provided input path {path} does not contain any text files.')

    return text_to_summarize


def get_attachments_for_prompt(path: str, **kwargs) -> list:
    """
    Creates a list of image attachments from JPEG files in a directory within a specified page range.

    Parameters
    ----------
    path : str
        The directory path containing JPEG image files.
    **kwargs
        Optional keyword arguments:
        start_page : int, optional
            The starting page index (default: 0).
        stop_page : int, optional
            The ending page index (inclusive, default: None).

    Returns
    -------
    list
        A list of llm.Attachment objects representing the image files.

    Raises
    ------
    RuntimeError
        If the provided path does not contain any JPEG files.
    """
    start = kwargs.get('start_page', 0)
    end = kwargs.get('stop_page', None)
    path = path.rstrip('/')
    attachments = []
    i = None
    for i, filepath in enumerate(sorted(glob(f'{path}/*.jpg'), key=_get_order)):
        if i < start or (end is not None and i > end):
            break
        print(filepath)
        attachments.append(llm.Attachment(path=filepath, type='image/jpeg'))
    if i is None:
        raise RuntimeError(f'Provided input path {path} does not contain any jpg files.')
    return attachments


def get_default_args(command_description: str) -> argparse.ArgumentParser:
    """
    Parses command-line arguments for input and output directories.

    Parameters
    ----------
    command_description : str
        A string describing the command.

    Returns
    -------
    argparse.Namespace
        An argparse.Namespace object containing the parsed arguments.
    """
    parser = argparse.ArgumentParser(
        prog=command_description, )
    parser.add_argument('input_directory', type=_dir_path, help='A directory containing text files to summarize.')
    parser.add_argument('output_directory', type=_dir_path, help='Where to put the summary results.')
    return parser


def pdf_to_images(input_path: str, output_path: str) -> None:
    """
    Converts a PDF file into a series of JPEG images, one for each page.

    Parameters
    ----------
    input_path : str
        The path to the input PDF file.
    output_path : str
        The directory path where the images will be saved.
    """
    images = pdf2image.convert_from_path(input_path, fmt='jpg')
    for page, image in enumerate(images):
        image.save(f"{output_path}/page-{page}.jpg")


def _get_order(file):
    """
    Sort helper to reliably order filenames with a numeric component.

    Parameters
    ----------
    file : str
        The filename.

    Returns
    -------
    int
        The numerical order, or math.inf if no number is found.
    """
    match = file_pattern.match(pathlib.Path(file).name)
    if not match:
        return math.inf
    return int(match.groups()[0])


def _dir_path(path: str) -> str:
    """
    Validates that a given path is a directory.

    Parameters
    ----------
    path : str
        The path to validate.

    Returns
    -------
    str
        The validated path.

    Raises
    ------
    argparse.ArgumentTypeError
        If the path is not a valid directory.
    """
    if os.path.isdir(path):
        return path
    else:
        raise argparse.ArgumentTypeError(f'Provided path, {path} is not a valid')

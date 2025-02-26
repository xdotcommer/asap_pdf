import argparse
import time
from collections import Counter
from heapq import nlargest

import nltk
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from spacy import cli, load
# This is required for some reason.
from spacytextblob.spacytextblob import SpacyTextBlob

from experiment import get_default_args, get_text_for_prompt, logger

"""
Tries to summarize some text via extractive approaches.
"""

nltk.download('punkt')
nltk.download('punkt_tab')
nltk.download('stopwords')

cli.download("en_core_web_sm")

nlp = load("en_core_web_sm")
nlp.add_pipe('spacytextblob')


def similarity_summarizer(text, percentage):
    # Tokenize the text into individual sentences
    sentences = nltk.tokenize.sent_tokenize(text)

    # Tokenize each sentence into individual words and remove stopwords
    stop_words = set(nltk.corpus.stopwords.words('english'))
    # the following line would tokenize each sentence from sentences into individual words using the word_tokenize function of nltk.tokenize module
    # Then removes any stop words and non-alphanumeric characters from the resulting list of words and converts them all to lowercase
    words = [word.lower() for word in nltk.tokenize.word_tokenize(text) if
             word.lower() not in stop_words and word.isalnum()]

    # Compute the frequency of each word
    word_freq = Counter(words)

    # Compute the score for each sentence based on the frequency of its words
    # After this block of code is executed, sentence_scores will contain the scores of each sentence in the given text,
    # where each score is a sum of the frequency counts of its constituent words

    # empty dictionary to store the scores for each sentence
    sentence_scores = {}

    for sentence in sentences:
        sentence_words = [word.lower() for word in nltk.tokenize.word_tokenize(sentence) if
                          word.lower() not in stop_words and word.isalnum()]
        sentence_score = sum([word_freq[word] for word in sentence_words])
        # if len(sentence_words) < 20:
        sentence_scores[sentence] = sentence_score

    # checks if the length of the sentence_words list is less than 20 (parameter can be adjusted based on the desired length of summary sentences)
    # If condition -> true, score of the current sentence is added to the sentence_scores dictionary with the sentence itself as the key
    # This is to filter out very short sentences that may not provide meaningful information for summary generation

    # Select the top n sentences with the highest scores
    top_n = int(len(sentences) * percentage)
    summary_sentences = sorted(sentence_scores, key=sentence_scores.get, reverse=True)[:top_n]
    summary = ' '.join(summary_sentences)

    # Return final summary
    return summary


def tfidf_summarizer(text, percentage):
    # Tokenize the text into individual sentences
    sentences = nltk.tokenize.sent_tokenize(text)

    # Create the TF-IDF matrix
    vectorizer = TfidfVectorizer(stop_words='english')
    tfidf_matrix = vectorizer.fit_transform(sentences)

    # Compute the cosine similarity between each sentence and the document
    sentence_scores = cosine_similarity(tfidf_matrix[-1], tfidf_matrix[:-1])[0]

    # Select the top n sentences with the highest scores
    top_n = int(len(sentences) * percentage)
    summary_sentences = nlargest(top_n, range(len(sentence_scores)), key=sentence_scores.__getitem__)

    summary_tfidf = ' '.join([sentences[i] for i in sorted(summary_sentences)])
    return summary_tfidf


def run_experiment(args: argparse.Namespace):
    """
    Tries some extractive text summary methods.

    Parameters
    ----------
    args: argparse.Namespace
      Arguments parsed from the command line.
    """
    logger.info('Loading input text.')
    input_text = get_text_for_prompt(args.input_directory)
    logger.info('Beginning token similarity experiment.')
    start = time.time()
    summary = similarity_summarizer(input_text, 0.1)
    duration = time.time() - start
    logger.info(f'Inference took {duration} seconds')
    with open(f'{args.output_directory}/extractive_token_similarity.txt', "w") as file:
        file.write(summary)

    logger.info('Beginning term frequency-inverse document frequency experiment.')
    start = time.time()
    summary = tfidf_summarizer(input_text, 0.1)
    duration = time.time() - start
    logger.info(f'Inference took {duration} seconds')
    with open(f'{args.output_directory}/extractive_tfidf.txt', "w") as file:
        file.write(summary)
    logger.info('All done!')


if __name__ == '__main__':
    provided_args = get_default_args('Try various extractive text summarization methods with spaCy.')
    run_experiment(provided_args.parse_args())

import argparse
import json
import logging

import llm
import pdf2image
import pypdf

# Create and provide a very simple logger implementation.
logger = logging.getLogger('experiment_utility')
formatter = logging.Formatter('%(asctime)s: %(message)s')
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
ch.setFormatter(formatter)
logger.addHandler(ch)


def get_config():
    with open('config.json', 'r') as f:
        return json.load(f)


def pdf_to_attachments(pdf_path: str, output_path: str, page_limit: int) -> list:
    images = pdf2image.convert_from_path(pdf_path, fmt='jpg')
    attachments = []
    for page, image in enumerate(images):
        if 0 < page_limit - 1 < page:
            break
        page_path = f'{output_path}/page-{page}.jpg'
        image.save(page_path)
        attachments.append(llm.Attachment(path=page_path, type='image/jpeg'))
    return attachments


total_tokens_used = {
    'input': 0,
    'output': 0,
}

initial_prompt = """
You are an expert in ADA compliance and accessibility requirements for government documents.

The U.S. Department of Justice ADA rule requires that state and local government websites make their web content and documents conform with WCAG 2.1 Level AA. There are three exemptions:
1. Archived Content: Was created before April 24th, 2026; Is retained exclusively for reference, research, or recordkeeping; Is not altered or updated after the date of archiving; and Is organized and stored in a dedicated area or areas clearly identified as being archived.
2. Not Fundamental for Program Use: Not, currently used to apply for, gain access to, or participate in the public entity’s services, programs, or activities.
3. Third Party: Content posted by a third party, unless the third party is posting due to contractual, licensing, or other arrangements with the public entity.

I am analyzing a PDF document from the City of San Rafael website. The document is titled "2023 Gann Appropriations Limit Report" and is located at "https://www.cityofsanrafael.org/documents/san-rafael-gann-2023".

The following jpg images are the pages from the document.
"""


def run_experiment(pdf_path: str):
    output = {
        'is_encrypted': pypdf.PdfReader(pdf_path).is_encrypted,
        'summary': '',
        'is_third_party': None,
        'why_third_party': '',
        'is_archival': None,
        'why_archival': '',
        'is_app': None,
        'why_app': '',
        'tokens': {},
    }
    if not output['is_encrypted']:
        config = get_config()
        model = llm.get_model(config['active_model'])
        model.key = config['key']
        attachments = pdf_to_attachments(pdf_path, './data', config['page_limit'])
        conversation = model.conversation()
        run_prompt(conversation, initial_prompt)

        response = run_prompt(conversation,
                              'Does this document meet the "Archival Content" exemption criteria? Just answer True or False.')
        output['is_archival'] = response.text().strip() == 'True'
        response = run_prompt(conversation, 'Provide a one sentence explanation of your answer.')
        output['why_archival'] = response.text().strip()
        run_prompt(conversation, initial_prompt)

        response = run_prompt(conversation,
                              'Does this document meet the "Not Fundamental for Program Use" exemption criteria? Just answer True or False.')
        output['is_app'] = response.text().strip() == 'True'
        response = run_prompt(conversation, 'Provide a one sentence explanation of your answer.')
        output['why_app'] = response.text().strip()

        response = run_prompt(conversation,
                              'Does this document meet the "Third Party" exemption criteria? Just answer True or False.')
        output['is_third_party'] = response.text().strip() == 'True'
        response = run_prompt(conversation, 'Provide a one sentence explanation of your answer.')
        output['why_third_party'] = response.text().strip()

        response = run_prompt(conversation,
                              'The following jpg images are the pages from the document. Could you summarize the document in two to three sentences?',
                              attachments=attachments)

        output['summary'] = response.text()
        output['tokens'] = total_tokens_used
    print(json.dumps(output))


def run_prompt(conversation, prompt, attachments=None):
    global total_tokens_used
    if attachments is None:
        response = conversation.prompt(prompt)
    else:
        response = conversation.prompt(prompt, attachments=attachments)
    usage = response.usage()
    total_tokens_used['input'] += usage.input
    total_tokens_used['output'] += usage.output
    return response


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Ask an LLM all kinds of questions about a document.")
    parser.add_argument("pdf_path", help="Path to pdf")
    args = parser.parse_args()
    run_experiment(args.pdf_path)

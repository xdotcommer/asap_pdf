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

ada_rule = """
§ 35.201 Exceptions.
The requirements of § 35.200 do not apply to the following:
(a) Archived web content. Archived web content as defined in § 35.104.
(b) Preexisting conventional electronic documents. Conventional electronic documents that
are available as part of a public entity’s web content or mobile apps before the date the public
entity is required to comply with this subpart, unless such documents are currently used to apply
for, gain access to, or participate in the public entity’s services, programs, or activities.
(c) Content posted by a third party. Content posted by a third party, unless the third party is
posting due to contractual, licensing, or other arrangements with the public entity.
(d) Individualized, password-protected or otherwise secured conventional electronic
documents. Conventional electronic documents that are:
(1) About a specific individual, their property, or their account; and
(2) Password-protected or otherwise secured.
(e) Preexisting social media posts. A public entity’s social media posts that were posted
before the date the public entity is required to comply with this subpart.

§ 35.104 Definitions.
* * * * *
Archived web content means web content that—
(1) Was created before the date the public entity is required to comply with subpart H of
this part, reproduces paper documents created before the date the public entity is required to
comply with subpart H, or reproduces the contents of other physical media created before the
date the public entity is required to comply with subpart H;
(2) Is retained exclusively for reference, research, or recordkeeping;
(3) Is not altered or updated after the date of archiving; and 
(4) Is organized and stored in a dedicated area or areas clearly identified as being archived.
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
        response = run_prompt(conversation,
                              f'The federal government has issued an ADA rule stating that local and state government file attachments must be WCAG 2.1 AA compliant. The compliance date is April 26, 2026. The list the following exemptions: {ada_rule}')
        response = run_prompt(conversation,
                              'I am analyzing local government PDF documents. The current document comes from a page entitled: "2023 Gann Appropriations Limit Report" with the url "https://www.cityofsanrafael.org/documents/san-rafael-gann-2023".')
        response = run_prompt(conversation,
                              'The following jpg images are the pages from the document. Could you summarize the document in two to three sentences? Just answer with the summary.',
                              attachments=attachments)
        output['summary'] = response.text()
        response = run_prompt(conversation,
                              'Does this document qualify for exemption "c"? Just answer True or False.')
        output['is_third_party'] = response.text().strip() == 'True'
        response = run_prompt(conversation, 'Provide a one sentence explanation of your answer.')
        output['why_third_party'] = response.text().strip()
        response = run_prompt(conversation,
                              'Does this document qualify for exemption "a"? Just answer True or False. Just answer True or False.')
        output['is_archival'] = response.text().strip() == 'True'
        response = run_prompt(conversation, 'Provide a one sentence explanation of your answer.')
        output['why_archival'] = response.text().strip()
        response = run_prompt(conversation,
                              'Does this document qualify for exemption "b"? Just answer True or False.')
        output['is_app'] = response.text().strip() == 'True'
        response = run_prompt(conversation, 'Provide a one sentence explanation of your answer.')
        output['why_app'] = response.text().strip()
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

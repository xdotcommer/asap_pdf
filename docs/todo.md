# TODO

## Rails App
- encoded url links are broken #35
- status => Backlog, In Review, Done (better name?)
- remove unknown or use Unknown instead of Other in csv files

## Crawler
- URLs with backslashes show up as empty filenames in the CSV files: http://www.slcdocs.com\recorder\BOE.pdf
- Seems like we're missing a lot of PDFs (Austin and Georgia mentioned they have a lot more)

## Classifier
- Use this list of classifications: "Agreement", "Agenda", "Brochure", "Diagram", "Flyer", "Form", "Form Instructions", "Job Announcement", "Job Description", "Letter", "Map", "Memo", "Policy", "Slides", "Press", "Procurement", "Notice", "Report", "Spreadsheet" (ideally load from json file for classifier and document.rb)
- Change "Other" to "Unknown"
- Review accuracy by classification.

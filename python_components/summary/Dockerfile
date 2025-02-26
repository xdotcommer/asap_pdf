FROM python:3.9
COPY requirements.txt .
ENV PYTHONPATH=\/workspace
ENV OLLAMA_HOST='http://ollama:11434'
RUN pip install -r requirements.txt --trusted-host pypi.python.org --no-cache-dir
WORKDIR /workspace
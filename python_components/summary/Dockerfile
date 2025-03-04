FROM python:3.12
COPY requirements.txt .
ENV PYTHONPATH=\/workspace
RUN apt-get update -y &&\
    apt-get install poppler-utils -y &&\
    pip install -r requirements.txt --trusted-host pypi.python.org --no-cache-dir
WORKDIR /workspace

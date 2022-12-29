FROM python:3.10-buster

WORKDIR app

COPY app/ .
COPY requirements.txt /tmp/requirements.txt

RUN pip install -r /tmp/requirements.txt
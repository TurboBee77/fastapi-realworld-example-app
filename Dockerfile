#-----Stage 1: pełne zależności pod pytest--------Build pod pytest--------------

FROM python:3.9.10-slim as builder

ENV PYTHONUNBUFFERED 1
WORKDIR /app


RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY poetry.lock pyproject.toml ./
RUN pip install poetry==1.1 "poetry-core<1.1.0" && \
    poetry config virtualenvs.in-project true && \
    poetry install && \
    poetry run pip install "setuptools<65.5.0"

COPY . ./


#-----------Stage 2: Zależności produkcyjne--------------------

FROM python:3.9.10-slim

ENV PYTHONUNBUFFERED 1

EXPOSE 8000
WORKDIR /app


RUN apt-get update && \
    apt-get install -y --no-install-recommends netcat && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY poetry.lock pyproject.toml ./
RUN pip install poetry==1.1 "poetry-core<1.1.0" && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-dev && \
    poetry run pip install "setuptools<65.5.0"

COPY . ./

CMD poetry run alembic upgrade head && \
    poetry run uvicorn --host=0.0.0.0 app.main:app

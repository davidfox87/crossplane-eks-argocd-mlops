FROM python:3.9.13-slim

RUN apt-get -y update
RUN apt-get install -y --fix-missing \
    libxml2 \
    gcc \
    vim \
    iputils-ping \
    telnet \
    procps \
    git \
    openjdk-11-jdk && apt-get clean && rm -rf /tmp/* /var/tmp/*


COPY requirements.txt .
RUN pip install -r requirements.txt

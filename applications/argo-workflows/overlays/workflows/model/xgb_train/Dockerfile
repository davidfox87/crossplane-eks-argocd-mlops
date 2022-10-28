FROM python:3.9-slim-buster

# copy requirements.txt into /app working dir
COPY requirements.txt requirements.txt 

# install python packages
RUN pip3 install -r requirements.txt

# copy source files into /app working dir
COPY ./src /opt/workdir
WORKDIR /opt/workdir


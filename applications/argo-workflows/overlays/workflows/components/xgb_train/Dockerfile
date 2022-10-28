FROM python:3.9-slim-buster
WORKDIR /app

# copy requirements.txt into /app working dir
COPY requirements.txt requirements.txt 

# install our dependencies
RUN pip3 install -r requirements.txt

# copy source files into /app working dir
COPY ./src . 

#ENTRYPOINT ["python3", "./cli.py"]
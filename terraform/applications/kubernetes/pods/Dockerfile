FROM python:3.7-slim

WORKDIR /app

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

# don't need this because k8s will override it
ENTRYPOINT [“python3”, “./main.py”] 
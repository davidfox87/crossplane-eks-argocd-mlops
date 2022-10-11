FROM python:3.7-slim

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
  rm requirements.txt

# Expose the port that the MLFlow tracking server runs on
EXPOSE 5000

ENV AWS_MLFLOW_BUCKET mlflow
ENV BACKEND_URI postgresql://postgresdb/mlflow

CMD mlflow server \
    --backend-store-uri ${BACKEND_URI} \
    --default-artifact-root s3://${AWS_MLFLOW_BUCKET}/artifacts \
    --host 0.0.0.0 \
    --port 5000

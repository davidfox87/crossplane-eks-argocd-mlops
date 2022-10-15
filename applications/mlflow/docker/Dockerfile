FROM python:3.7-slim

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt && \
  rm requirements.txt && mkdir /mlflow/

# Expose the port that the MLFlow tracking server runs on
EXPOSE 5000
ENTRYPOINT ["mlflow", "server"]

# ENV BACKEND_URI postgresql://${PG_USER}:${PG_PASSWORD}@${PG_HOST}:5432/${PG_DATABASE}

# RUN echo ${BACKEND_URI}

# CMD mlflow server \
#     --backend-store-uri ${BACKEND_URI} \
#     --default-artifact-root s3://${AWS_MLFLOW_BUCKET}/ \
#     --host 0.0.0.0 \
#     --port 5000

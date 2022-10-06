FROM python:3.6
RUN apt update && apt install -y python3-venv gcc
RUN apt-get install -y python3-dev build-essential

ENV VENV=/.venv/myenv
RUN python3 -m venv ${VENV}
RUN mkdir -p $VENV/src
ENV PATH=$VENV/bin:$PATH
RUN pip install -U pip
RUN pip install mlflow \
                boto3 \
                pymysql \
                psycopg2-binary

# Mount the credentials json file under the following directory
RUN mkdir -p /workdir/gcloud-credentials/
WORKDIR /workdir/


# Make sure your credentials file is named gcloud-credentials.json too


# Expose the port that the MLFlow tracking server runs on
EXPOSE 5000
# Default database credentials
ENV DB_USERNAME=admin
ENV DB_PASSWORD=password
ENV DB_URL=mlflow-database:5432
ENV DB_NAME=mlflow-tracking-server-db

ENTRYPOINT mlflow server \
        --default-artifact-root $ARTIFACT_STORE \
        --backend-store-uri postgresql://$DB_USERNAME:$DB_PASSWORD@$DB_URL/$DB_NAME --host 0.0.0.0
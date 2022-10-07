FROM python:3.7

RUN pip install -U pip
RUN pip install mlflow \
                boto3 \
                pymysql \
                psycopg2-binary


# Expose the port that the MLFlow tracking server runs on
EXPOSE 5000

ENV AWS_MLFLOW_BUCKET aws_mlflow_bucket
ENV AWS_ACCESS_KEY_ID aws_access_key_id
ENV AWS_SECRET_ACCESS_KEY aws_secret_access_key

COPY run.sh /

ENTRYPOINT ["/run.sh"]


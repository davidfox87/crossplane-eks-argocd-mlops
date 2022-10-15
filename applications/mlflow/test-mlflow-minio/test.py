import mlflow
from mlflow.entities import Param,Metric,RunTag
import boto3
import pandas as pd
import os

os.environ['MLFLOW_S3_ENDPOINT_URL'] = 'http://localhost:9200' #minio API
os.environ['AWS_ACCESS_KEY_ID'] = 'minio'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'minio123'

print("MLflow Version:", mlflow.__version__)
mlflow.set_tracking_uri("http://localhost:5555")
print("Tracking URI:", mlflow.tracking.get_tracking_uri())

with mlflow.start_run(run_name='test') as run:
    with open("info.txt", "w") as f:
        f.write("Hi artifact")
    mlflow.log_artifact("info.txt")
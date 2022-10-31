import mlflow
from mlflow.entities import Param,Metric,RunTag
import boto3
import pandas as pd
import os

os.environ['MLFLOW_S3_ENDPOINT_URL'] = 'http://localhost:9200' #minio API
os.environ['AWS_ACCESS_KEY_ID'] = 'minio'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'minio123'

print("MLflow Version:", mlflow.__version__)
mlflow.set_tracking_uri("http://localhost:5566")
print("Tracking URI:", mlflow.tracking.get_tracking_uri())

model_uri = 's3://mlflow/1/ce3d84082d924370b971e39ad2cc1366/artifacts/xgboost-model/'
model = mlflow.pyfunc.load_model(model_uri)

model.predict()

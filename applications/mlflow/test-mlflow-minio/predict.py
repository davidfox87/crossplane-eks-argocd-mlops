from argparse import ArgumentParser
import pandas as pd
from sklearn.model_selection import train_test_split
import xgboost as xgb
import mlflow
import mlflow.xgboost
import os 


os.environ['MLFLOW_S3_ENDPOINT_URL'] = 'http://localhost:9200' #minio API
os.environ['AWS_ACCESS_KEY_ID'] = 'minio'
os.environ['AWS_SECRET_ACCESS_KEY'] = 'minio123'

print("MLflow Version:", mlflow.__version__)
mlflow.set_tracking_uri("http://localhost:5566")
print("Tracking URI:", mlflow.tracking.get_tracking_uri())


print("Tracking URI:", mlflow.tracking.get_tracking_uri())
print("MLflow Version:", mlflow.__version__)
print("XGBoost version:",xgb.__version__)

def build_data(data_path):
    data = pd.read_csv(data_path)
    X = data.drop(["quality"], axis=1)
    y = data["quality"]
    return X, y

if __name__ == "__main__":
    parser = ArgumentParser()
    parser.add_argument("--model_uri", dest="model_uri", help="model_uri", required=True)
    parser.add_argument("--data_path", dest="data_path", help="data_path", default="data/wine-quality-red.csv")
    args = parser.parse_args()
    print("Arguments:")
    for arg in vars(args):
        print(f"  {arg}: {getattr(args, arg)}")

    X,y  = build_data(args.data_path)
        
    # model = mlflow.xgboost.load_model(args.model_uri)
    model_uri = 's3://mlflow/1/ce3d84082d924370b971e39ad2cc1366/artifacts/xgboost-model/'
    print("\n=== mlflow.pyfunc.load_model")
    model = mlflow.pyfunc.load_model(args.model_uri)
    print("model:", model)
    print("predicting for: ", X.iloc[:2, :])
    predictions = model.predict(X.iloc[:2, :])
    print("predictions.type:", type(predictions))
    print("predictions.shape:", predictions.shape)
    print("predictions:", predictions)

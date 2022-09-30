import argparse
import logging
import joblib
import pandas as pd
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer
from xgboost import XGBRegressor

import argparse
from datetime import datetime

logging.basicConfig(format='%(message)s')
logging.getLogger().setLevel(logging.INFO)

def save_model(model, model_file):
        """Save XGBoost model for serving."""
        joblib.dump(model, model_file)
        logging.info("Model export success: %s", model_file)

def train_model(train_X, train_y,test_X, test_y, bucket, model_file,
                n_estimators=100, learning_rate=0.1):
        """Train the model using XGBRegressor."""
        model = XGBRegressor(n_estimators=n_estimators, learning_rate=learning_rate)

        model.fit(train_X,
                train_y,
                early_stopping_rounds=40,
                eval_set=[(test_X, test_y)])

        print("Best RMSE on eval: %.2f with %d rounds" %
                (model.best_score,
                model.best_iteration+1))

        s3_path = bucket + "/" + model_file

        joblib.dump(model, s3_path)
        logging.info("Model export success: %s", model_file)

if __name__ == '__main__':

        parser = argparse.ArgumentParser()
        parser.add_argument(
        '--model_file', type=str, required=True, help='Name of the model file.')
        parser.add_argument(
        '--bucket', type=str, required=True, help='S3 bucket name.')
        args = parser.parse_args()

        bucket=args.bucket
        model_file=args.model_file


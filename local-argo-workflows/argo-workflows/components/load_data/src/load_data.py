import argparse
import logging
import joblib
import sys
import pandas as pd
from sklearn.metrics import mean_absolute_error
from sklearn.model_selection import train_test_split
from sklearn.impute import SimpleImputer
from xgboost import XGBRegressor

def read_input(bucket, file_name, test_size=0.25):
    """Read input data and split it into train and test."""
    data = pd.read_csv(f'{bucket}/{file_name}')
    data.dropna(axis=0, subset=['SalePrice'], inplace=True)

    y = data.SalePrice
    X = data.drop(['SalePrice'], axis=1).select_dtypes(exclude=['object'])

    train_X, test_X, train_y, test_y = train_test_split(X.values,
                                                      y.values,
                                                      test_size=test_size,
                                                      shuffle=False)

    imputer = SimpleImputer()
    train_X = imputer.fit_transform(train_X)
    test_X = imputer.transform(test_X)

    return (train_X, train_y), (test_X, test_y)


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument(
    '--data_file', type=str, required=True, help='location of the data')
    parser.add_argument(
    '--bucket', type=str, required=True, help='S3 bucket name.')
    args = parser.parse_args()

    bucket=args.bucket
    filename=args.model_file

    read_input(bucket, filename, test_size=0.25)
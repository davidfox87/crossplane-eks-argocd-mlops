import argparse
import logging
import joblib
import pandas as pd
from sklearn.model_selection import train_test_split
from xgboost import XGBRegressor
from sklearn import datasets
import argparse
import sys

logging.basicConfig(format='%(message)s')
logging.getLogger().setLevel(logging.INFO)

iris = datasets.load_iris()
def load_data():
        iris = datasets.load_iris(as_frame=True)
        df = pd.concat([iris.data, iris.target], axis=1)
        logging.info('loading of data complete...')        
        df.to_csv('/tmp/iris.csv')

def save_model(model, model_file):
        """Save XGBoost model for serving."""
        joblib.dump(model, model_file)
        logging.info("Model export success: %s", model_file)


def parse_arguments(argv):
        """Parse command line arguments
        Args:
        argv (list): list of command line arguments including program name
        Returns:
        The parsed arguments as returned by argparse.ArgumentParser
        """
        parser = argparse.ArgumentParser(description='Training')

        parser.add_argument('--bucket',
                        type=str,
                        help='s3 bucket to store data and ML models',
                        default='<your-bucket-name>')

        parser.add_argument('--blob_path',
                        type=str,
                        help='s3 blob path where data is saved',
                        default='data')

        args, _ = parser.parse_known_args(args=argv[1:])

        return args


def train_model(argv=None):
        """Train the model using XGBRegressor."""
        args = parse_arguments(sys.argv if argv is None else argv)
         # get the data
        logging.info('getting the data...')
        df = pd.read_csv("/tmp/input.csv")
        X = df.drop('target', axis=1)
        y = df.loc[:, 'target']

        train_X, test_X, train_y, test_y = train_test_split(X, y, test_size=0.25)

        model = XGBRegressor(n_estimators=100, learning_rate=0.1)

        model.fit(train_X,
                train_y,
                early_stopping_rounds=40,
                eval_set=[(test_X, test_y)])

        print("Best RMSE on eval: %.2f with %d rounds" %
                (model.best_score,
                model.best_iteration+1))

        s3_path = bucket + "/" + model_file
        print("path is ", s3_path)

        save_model(model, s3_path)

if __name__ == '__main__':

        parser = argparse.ArgumentParser()
        parser.add_argument(
        '--model_file', type=str, required=True, help='Name of the model file.')
        parser.add_argument(
        '--bucket', type=str, required=True, help='S3 bucket name.')
        args = parser.parse_args()

        bucket=args.bucket
        model_file=args.model_file # 'iris-xgb.pkl'

        train_model(bucket, model_file)


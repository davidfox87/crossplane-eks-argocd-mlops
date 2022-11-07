import argparse
import logging
import joblib
import pandas as pd
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier
import argparse
import sys
import os 


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

        parser.add_argument('--model_file',
                        type=str,
                        help='s3 blob model file name',
                        default='model.pkl')

        args, _ = parser.parse_known_args(args=argv[1:])

        return args


def run_training(argv=None):
        """Train the model using XGBRegressor."""
        args = parse_arguments(sys.argv if argv is None else argv)
         # get the data
        logging.info('getting the data...')
        df = pd.read_csv("/tmp/data.csv")

        X = df.drop('target', axis=1)
        y = df.loc[:, 'target']

        train_X, test_X, train_y, test_y = train_test_split(X, y, test_size=0.25)
        n_estimators = 100
        learning_rate = 0.1
        
        model = XGBClassifier(n_estimators=n_estimators, 
                                learning_rate=learning_rate, 
                                early_stopping_rounds=10)

        logging.info('Training the classifier...')
        model.fit(train_X,
                train_y,
                eval_set=[(test_X, test_y)])

        print("Best RMSE on eval: %.2f with %d rounds" %
                (model.best_score,
                model.best_iteration+1))


        s3_path = args.bucket + "/" + args.model_file
        s3_path = '/tmp/model.pkl'
        logging.info('saving the classifier model artifact to %s', s3_path)

        save_model(model, '/tmp/model.pkl')



if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  run_training()
import logging

import numpy as np
import pandas as pd
from sklearn import datasets

logging.basicConfig(format='%(message)s')
logging.getLogger().setLevel(logging.INFO)

iris = datasets.load_iris()
def load_data():
        iris = datasets.load_iris(as_frame=True)
        df = pd.concat([iris.data, iris.target], axis=1)
        logging.info('loading of data complete...')        
        df.to_csv('/tmp/out.csv')

def preprocess_data(data=None):
    ...

def train_test_split(training_test_data, train_test_ratio=0.8):
  """Splits the data into a training and test set according to the provided ratio.
    """
  predictors = training_test_data[training_test_data.columns[2:]]
  classes = training_test_data[training_test_data.columns[:2]]

  training_set_size = int(len(training_test_data) * train_test_ratio)

  train_test_dict = {'training_predictors_tf': predictors[:training_set_size],
                     'training_classes_tf': classes[:training_set_size],
                     'test_predictors_tf': predictors[training_set_size:],
                     'test_classes_tf': classes[training_set_size:]}

  return train_test_dict
import logging

import numpy as np
import pandas as pd
from sklearn import datasets

logging.basicConfig(format='%(message)s')
logging.getLogger().setLevel(logging.INFO)


def load_data():
    iris = datasets.load_iris(as_frame=True)
    df = pd.concat([iris.data, iris.target], axis=1)
    logging.info('loading of data complete...')        
    df.to_csv('/tmp/data.csv')

def preprocess_data(data=None):
    pass

def train_test_split(training_test_data, train_test_ratio=0.8):
  """Splits the data into a training and test set according to the provided ratio.
    """
  # split 

  # write train and test to json, which can be passed as artifacts
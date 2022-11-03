"""Module for running the data retrieval and preprocessing.
Scripts that performs all the steps to get the train and perform preprocessing.
"""
import logging
import argparse
import sys

#pylint: disable=no-name-in-module
from helpers import preprocess



def parse_arguments(argv):
  """Parse command line arguments
  Args:
      argv (list): list of command line arguments including program name
  Returns:
      The parsed arguments as returned by argparse.ArgumentParser
  """
  parser = argparse.ArgumentParser(description='Preprocessing')

  parser.add_argument('--bucket',
                      type=str,
                      help='S3 bucket where preprocessed data is saved',
                      default='<your-bucket-name>')

  args, _ = parser.parse_known_args(args=argv[1:])

  return args


def run_preprocess(argv=None):
  """Runs the retrieval and preprocessing of the data.
  Args:
    args: args that are passed when submitting the training
  Returns:
  """
  logging.info('starting preprocessing of data..')
  args = parse_arguments(sys.argv if argv is None else argv)

  preprocess.load_data()

if __name__ == '__main__':
  logging.basicConfig(level=logging.INFO)
  run_preprocess()
import logging
import boto3
from botocore.exceptions import ClientError
import os
import argparse

def upload_file(bucket, object_name=None):
    """Upload a file to an S3 bucket

    :param file_name: File to upload
    :param bucket: Bucket to upload to
    :param object_name: S3 object name. If not specified then file_name is used
    :return: True if file was uploaded, else False
    """

    # If S3 object_name was not specified, use file_name
    if object_name is None:
        object_name = os.path.basename('s3-test.txt')

    # Upload the file
    s3_client = boto3.client('s3')
    try:
        response = s3_client.upload_file('s3-test.txt', bucket, object_name)
    except ClientError as e:
        logging.error(e)
        return False
    
    logging.info('Successfully uploaded file s3-test.txt to bucket %s', bucket)
    return True


if __name__ == "__main__":

    # Defining and parsing the command-line arguments
    parser = argparse.ArgumentParser(description='My program description')
    # Paths must be passed in, not hardcoded
    parser.add_argument('--bucket_name', type=str,
                        help='Name of the s3 bucket')
    
    args = parser.parse_args()

    bucket = args.bucket_name

    upload_file(bucket)
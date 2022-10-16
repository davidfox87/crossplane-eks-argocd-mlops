See this link for info on IRSA, which i use to grant access to the artifact s3 bucket to the mlflow deployment pods
https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/

Any other pod that needs access to the bucket can assume the IAM role with the S3 full access policy attached by assoicating the serviceAccountName

Make sure the s3 bucket exists before running. Presumably it does exist since you created the IAM role and policy to access that bucket in terraform.
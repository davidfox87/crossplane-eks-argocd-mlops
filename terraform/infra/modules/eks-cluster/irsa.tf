# resource "kubernetes_service_account" "eks-service-account" {
#   metadata {
#     name = "demo-user" # This is used as the serviceAccountName in the spec section of the k8 pod manifest
#                         # it means that the pod can assume the IAM role with the S3 policy attached
#     namespace = "default"
    
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.eks-service-account-role.arn
#     }
#   }
#   automount_service_account_token = true
# }


resource "aws_iam_role" "eks-service-account-role" {
  name = "iam-test"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["sts:AssumeRoleWithWebIdentity"]
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks-cluster.arn
        }
      },
    ]
  })

  inline_policy {
    name = "eks_service_account_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
            "Sid": "ListObjectsInBucket",
            "Effect": "Allow",
            "Action": "s3:ListBucket",
            "Resource": ["arn:aws:s3:::my-test-k8s-bucket"]
        },
        {
            "Sid": "AllObjectActions",
            "Effect": "Allow",
            "Action": "s3:*Object",
            "Resource": ["arn:aws:s3:::my-test-k8s-bucket/*"]
        }
      ]
    })
  }
}

resource aws_iam_role_policy_attachment s3_full_access {
  role = aws_iam_role.eks-service-account-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
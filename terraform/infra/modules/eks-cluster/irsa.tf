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
}

resource aws_iam_role_policy_attachment s3_full_access {
  role = aws_iam_role.eks-service-account-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

 resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Worker policy for the ALB Ingress"

  policy = file("iam-policy.json")
}

 resource "aws_iam_role_policy_attachment" "WorkerNodeALBIngress" {
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
  role    = aws_iam_role.eks-service-account-role.name
 }
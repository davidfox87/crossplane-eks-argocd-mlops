resource "kubernetes_service_account" "eks-service-account" {
  metadata {
    name = "aws-load-balancer-controller" # This is used as the serviceAccountName in the spec section of the k8 pod manifest
                                          # it means that the pod can assume the IAM role with the S3 policy attached
    namespace = "kube-system"
    
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks-service-account-role.arn
    }
  }
  automount_service_account_token = true
}


# Get information about the TLS certificates securing a host.
data "tls_certificate" "demo" {
  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks-cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.demo.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

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

 resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Worker policy for the ALB Ingress"

  policy = file("${path.module}/iam_policy.json")
}

 resource "aws_iam_role_policy_attachment" "WorkerNodeALBIngress" {
  policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
  role    = aws_iam_role.eks-service-account-role.name
 }







#  module "iam_eks_role" {
#   source    = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   role_name = "aws-load-balancer-controller"

#   oidc_providers = {
#     one = {
#       provider_arn               = aws_iam_openid_connect_provider.eks-cluster.arn
#       namespace_service_accounts = ["kube-system:alb-controller"]
#     }
#   }
#   role_policy_arns = {
   
#   }
#  }
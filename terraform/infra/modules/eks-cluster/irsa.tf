locals {
  k8s_service_account_namespace       = "argo"
  k8s_service_account_name            = "s3-access"
  k8s_service_account_namespace2       = "kube-system"
  k8s_service_account_name2            = "aws-load-balancer-controller"
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


module "iam_assumable_role_s3_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.0"

  create_role                   = true
  role_name                     = "s3-access"
  provider_url                  = replace(aws_iam_openid_connect_provider.eks-cluster.url, "https://", "")
  role_policy_arns              = [aws_iam_policy.s3_access.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
}
data "aws_iam_policy_document" "s3-access" {
  version = "2012-10-17"
  statement {
    sid = "Fetch"
    effect = "Allow"
    actions = [ "s3:GetObject",
                "s3:PutObject",
                "s3:ListBucket",
                "s3:GetBucketLocation"
    ]
    resources = [ "arn:aws:s3::::*" ]
  }
}

resource "aws_iam_policy" "s3_access" {
  name_prefix = "s3_access"
  description = "s3 access for pods run by argo workflows in ${var.cluster-name}"
  policy      = data.aws_iam_policy_document.s3-access.json
}







module "iam_assumable_role_lb" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.0"

  create_role                   = true
  role_name                     = "aws-load-balancer-controller"
  provider_url                  = replace(aws_iam_openid_connect_provider.eks-cluster.url, "https://", "")
  role_policy_arns              = [aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_service_account_namespace2}:${local.k8s_service_account_name2}"]
}


 resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Worker policy for the ALB Ingress"

  policy = file("${path.module}/iam_policy.json")
}









# resource "kubernetes_service_account" "eks-service-account" {
#   metadata {
#     name = "aws-load-balancer-controller" # This is used as the serviceAccountName in the spec section of the k8 pod manifest
#                                           # it means that the pod can assume the IAM role with the S3 policy attached
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/component": "controller"
#       "app.kubernetes.io/name": "aws-load-balancer-controller"
#     }
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.eks-service-account-role.arn
#     }
#   }
#   automount_service_account_token = true
# }


# resource "aws_iam_role" "eks-service-account-role" {
#   name = "iam-test"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = ["sts:AssumeRoleWithWebIdentity"]
#         Effect = "Allow"
#         Sid    = ""
#         Principal = {
#           Federated = aws_iam_openid_connect_provider.eks-cluster.arn
#         }
#       },
#     ]
#   })
# }




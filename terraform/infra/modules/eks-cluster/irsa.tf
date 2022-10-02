

data "aws_eks_cluster" "example" {
  name = aws_eks_cluster.demo.id
}
data "aws_eks_cluster_auth" "example" {
  name = aws_eks_cluster.demo.id
}
# Get information about the TLS certificates securing a host.

# Get information about the TLS certificates securing a host.
data "tls_certificate" "demo" {
  url = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks-cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.demo.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.demo.identity[0].oidc[0].issuer
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.example.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster-name]
    command     = "aws"
  }
}
resource "kubernetes_service_account" "eks-service-account" {
  metadata {
    name = local.k8s_service_account_name # This is used as the serviceAccountName in the spec section of the k8 pod manifest
                                          # it means that the pod can assume the IAM role with the S3 policy attached
    namespace = local.k8s_service_account_namespace
    labels = {
      "app.kubernetes.io/component": "controller"
      "app.kubernetes.io/name": "${local.k8s_service_account_name}"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.eks-service-account-role.arn
    }
  }
}

resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "Worker policy for the ALB Ingress"

  policy = file("${path.module}/iam_policy.json")
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

resource "aws_iam_role_policy_attachment" "AWSLoadBalancerControllerIAMPolicy" {
 policy_arn = aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn
 role    = aws_iam_role.eks-service-account-role.name
}


module "iam_assumable_role_s3_access" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 4.0"

  create_role                   = true
  role_name                     = "s3-access"
  provider_url                  = replace(aws_iam_openid_connect_provider.eks-cluster.url, "https://", "")
  role_policy_arns              = [aws_iam_policy.s3_access.arn]
  oidc_fully_qualified_subjects = ["${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"]
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



# module "iam_assumable_role_lb" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "~> 4.0"
#   create_role                   = true
#   role_name                     = "aws-load-balancer-controller"
#   provider_url                  = replace(aws_iam_openid_connect_provider.eks-cluster.url, "https://", "")
#   role_policy_arns              = [aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn]
#   oidc_fully_qualified_subjects = ["${local.k8s_service_account_namespace2}:${local.k8s_service_account_name2}"]
# }






# module "load_balancer_controller_irsa_role" {
#   source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

#   role_name                              = "load-balancer-controller"
#   attach_load_balancer_controller_policy = true

#   oidc_providers = {
#     ex = {
#       provider_arn               = aws_iam_openid_connect_provider.eks-cluster.arn 
#       namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#     }
#   }

#   tags = {"name" : "aws-load-balancer-controller"}
# }




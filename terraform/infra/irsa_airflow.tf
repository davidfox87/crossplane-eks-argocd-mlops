module "iam_assumable_role_airflow" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.4.0"
  create_role                   = true
  role_name                     = "${var.cluster-name}-airflow"
  provider_url                  = replace(module.eks_cluster.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.airflow_s3_access.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${var.airflow_namespace}:${var.airflow_sa_name}"]
}

# associate an IAM role with a Kubernetes service account
# and configure your pods to use the service account. This will
# give pods running under the service read/write access to s3
data "aws_iam_policy_document" "example" {
  statement {
    sid = "1"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
    ]

    resources = [
      "arn:aws:s3:::*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
    ]

  }

  statement {
    actions = [
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}",
      "arn:aws:s3:::${var.s3_bucket_name}/*",
    ]
  }
}

resource "aws_iam_policy" "airflow_s3_access" {
  name   = "example_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.example.json
}


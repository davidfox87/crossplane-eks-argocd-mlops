resource "aws_eks_cluster" "demo" {
  name            = "${var.cluster-name}"
  role_arn        = "${aws_iam_role.eks-iam-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.cluster_security_group_id.id}"]
    subnet_ids         =  "${var.subnets}"
  }
  version = "1.21" # kubeflow install manifests won't work with latest version of Kubernetes
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
  ]
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

resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "example-nodes"
  node_role_arn   = aws_iam_role.workernodes.arn
  subnet_ids      = [var.subnets[2], var.subnets[3]] # private subnets

  instance_types = ["t3.small"]#["m5.xlarge"]
  scaling_config {
    desired_size = 2#5
    max_size     = 5#10
    min_size     = 2# 5
  }

  # launch_template {
  #   # custom spec for worker nodes goes here  
  # }

  update_config {
    max_unavailable = 1
  }
  tags = {
    "alpha.eksctl.io/cluster-name" = "${var.cluster-name}"
    "eksctl.cluster.k8s.io/v1alpha1/cluster-name" = "${var.cluster-name}"
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}

# data "aws_ami" "eks-worker" {
#   filter {
#     name   = "name"
#     values = ["amazon-eks-node-${aws_eks_cluster.demo.version}-v*"]
#   }

#   most_recent = true
#   owners      = ["602401143452"] # Amazon EKS AMI Account ID
# }

# resource "aws_launch_template" "foo" {
#   name = "foo"

#   image_id = "${data.aws_ami.eks-worker.id}"
#   instance_type = "m5.xlarge"
#   monitoring {
#     enabled = true
#   }

#   network_interfaces {
#     associate_public_ip_address = true
#   }
#   #vpc_security_group_ids = []
# }



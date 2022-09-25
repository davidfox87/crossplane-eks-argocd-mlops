resource "aws_eks_cluster" "demo" {
  name            = "${var.cluster-name}"
  version         = var.kubernetes_version
  role_arn        = "${aws_iam_role.eks-iam-role.arn}"

  vpc_config {
    security_group_ids = ["${aws_security_group.cluster_security_group_id.id}"]
    subnet_ids         =  "${var.subnets}"
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy,
  ]
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

variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.21.2-eksbuild.2"
    },
    {
      name    = "vpc-cni"
      version = "v1.10.1-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.8.4-eksbuild.1"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.4.0-eksbuild.preview"
    }
  ]
}


resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.demo.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts = "OVERWRITE"
  depends_on = [aws_eks_node_group.example] 
}












# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "18.29.0"


#   cluster_name                    = local.name
#   cluster_endpoint_private_access = true
#   cluster_endpoint_public_access  = true

#   cluster_addons = {
#     coredns = {
#       resolve_conflicts = "OVERWRITE"
#     }
#     kube-proxy = {}
#     vpc-cni = {
#       resolve_conflicts = "OVERWRITE"
#     }
#   }

#   # Encryption key
#   create_kms_key = true
#   cluster_encryption_config = [{
#     resources = ["secrets"]
#   }]
#   kms_key_deletion_window_in_days = 7
#   enable_kms_key_rotation         = true

#   vpc_id                   = module.vpc.vpc_id
#   subnet_ids               = module.vpc.private_subnets
#   control_plane_subnet_ids = module.vpc.intra_subnets

#   # Extend cluster security group rules
#   cluster_security_group_additional_rules = {
#     egress_nodes_ephemeral_ports_tcp = {
#       description                = "To node 1025-65535"
#       protocol                   = "tcp"
#       from_port                  = 1025
#       to_port                    = 65535
#       type                       = "egress"
#       source_node_security_group = true
#     }
#   }

#   # Extend node-to-node security group rules
#   node_security_group_ntp_ipv4_cidr_block = ["169.254.169.123/32"]
#   node_security_group_additional_rules = {
#     ingress_self_all = {
#       description = "Node to node all ports/protocols"
#       protocol    = "-1"
#       from_port   = 0
#       to_port     = 0
#       type        = "ingress"
#       self        = true
#     }
#     egress_all = {
#       description      = "Node all egress"
#       protocol         = "-1"
#       from_port        = 0
#       to_port          = 0
#       type             = "egress"
#       cidr_blocks      = ["0.0.0.0/0"]
#       ipv6_cidr_blocks = ["::/0"]
#     }
#   }

#   # Self Managed Node Group(s)
#   self_managed_node_group_defaults = {
#     vpc_security_group_ids       = [aws_security_group.additional.id]
#     iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
#   }

#   self_managed_node_groups = {
#     spot = {
#       instance_type = "m5.large"
#       instance_market_options = {
#         market_type = "spot"
#       }

#       pre_bootstrap_user_data = <<-EOT
#       echo "foo"
#       export FOO=bar
#       EOT

#       bootstrap_extra_args = "--kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=spot'"

#       post_bootstrap_user_data = <<-EOT
#       cd /tmp
#       sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
#       sudo systemctl enable amazon-ssm-agent
#       sudo systemctl start amazon-ssm-agent
#       EOT
#     }
#   }




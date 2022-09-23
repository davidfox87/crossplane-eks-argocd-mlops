module "network" {
  source = "./modules/my-vpc"

  environment = "dev"
  cluster-name = var.cluster-name
  region = var.region
}

module "my-eks" {
    source = "./modules/eks-cluster"

    cluster-name = var.cluster-name
    vpc_id = module.network.vpc_id
    subnets = concat(module.network.vpc_public_subnets,  module.network.vpc_private_subnets)

}


# get info about the EKS cluster to pass to helm
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "helm" {
  version = "1.3.1"
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token
    load_config_file       = false
  }
}

#install the AWS Load Balancer Controller
resource "helm_release" "ingress" {
  name       = "ingress"
  chart      = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  version    = "1.0.2"
  namespace = "kube-system"
  set {
    name  = "region"
    value = "us-west-1"
  }
  set {
    name  = "vpcId"
    value =  "${module.network.vpc_id}"
  }
  set {
    name  = "image.repository"
    value =  "602401143452.dkr.ecr.region-code.amazonaws.com/amazon/aws-load-balancer-controller"
  }
  set {
    name  = "clusterName"
    value =  "${module.my-eks.cluster_name}"
  }
  set {
    name  = "serviceAccount.create"
    value =  "false"
  }

  set {
    name  = "serviceAccount.name"
    value =  "aws-load-balancer-controller "
  }
}

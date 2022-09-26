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


# # get info about the EKS cluster to pass to helm
data "aws_eks_cluster" "cluster" {
  name = module.my-eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.my-eks.cluster_name
}

# # https://learn.hashicorp.com/tutorials/terraform/helm-provider?in=terraform/kubernetes
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.example.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.example.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
      command     = "aws"
    }
  }
}


# The Terraform Helm provider contains the helm_release resource that deploys 
# a Helm chart to a Kubernetes cluster. The helm_release resource specifies the
# chart name and the configuration variables for your deployment.

# Installs helm chart for the aws-load-balancer-controller.
resource "helm_release" "ingress" {
  depends_on = [
    module.my-eks
  ]
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

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
    value =  "602401143452.dkr.ecr.us-west-1.amazonaws.com/amazon/aws-load-balancer-controller"
  }
  set {
    name  = "clusterName"
    value =  "${var.cluster-name}"
  }
  set {
    name  = "serviceAccount.create"
    value =  "false"
  }

  set {
    name  = "serviceAccount.name"
    value =  "aws-load-balancer-controller"
  }
}



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
  name = module.my-eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.my-eks.cluster_id
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster.token

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
      command     = "aws"
    }
  }
}

# Installs helm chart for the aws-load-balancer-controller.
resource "helm_release" "ingress" {
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






# provider "aws" {
#   region = "ap-south-1"
# }

# data "aws_eks_cluster" "cluster" {
#   name = module.eks.cluster_id
# }

# data "aws_eks_cluster_auth" "cluster" {
#   name = module.eks.cluster_id
# }

# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.cluster.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
#   load_config_file       = false
#   version                = "~> 1.11"
# }

# data "aws_availability_zones" "available" {
# }

# locals {
#   cluster_name = "my-cluster"
# }

# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "2.47.0"

#   name                 = "k8s-vpc"
#   cidr                 = "172.16.0.0/16"
#   azs                  = data.aws_availability_zones.available.names
#   private_subnets      = ["172.16.1.0/24", "172.16.2.0/24", "172.16.3.0/24"]
#   public_subnets       = ["172.16.4.0/24", "172.16.5.0/24", "172.16.6.0/24"]
#   enable_nat_gateway   = true
#   single_nat_gateway   = true
#   enable_dns_hostnames = true

#   public_subnet_tags = {
#     "kubernetes.io/cluster/${local.cluster_name}" = "shared"
#     "kubernetes.io/role/elb"                      = "1"
#   }

#   private_subnet_tags = {
#     "kubernetes.io/cluster/${local.cluster_name}" = "shared"
#     "kubernetes.io/role/internal-elb"             = "1"
#   }
# }

# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "12.2.0"

#   cluster_name    = "${local.cluster_name}"
#   cluster_version = "1.17"
#   subnets         = module.vpc.private_subnets

#   vpc_id = module.vpc.vpc_id

#   node_groups = {
#     first = {
#       desired_capacity = 1
#       max_capacity     = 10
#       min_capacity     = 1

#       instance_type = "m5.large"
#     }
#   }

#   write_kubeconfig   = true
#   config_output_path = "./"

#   workers_additional_policies = [aws_iam_policy.worker_policy.arn]
# }

# resource "aws_iam_policy" "worker_policy" {
#   name        = "worker-policy"
#   description = "Worker policy for the ALB Ingress"

#   policy = file("iam-policy.json")
# }

# provider "helm" {
#   version = "1.3.1"
#   kubernetes {
#     host                   = data.aws_eks_cluster.cluster.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
#     token                  = data.aws_eks_cluster_auth.cluster.token
#     load_config_file       = false
#   }
# }

# resource "helm_release" "ingress" {
#   name       = "ingress"
#   chart      = "aws-alb-ingress-controller"
#   repository = "http://storage.googleapis.com/kubernetes-charts-incubator"
#   version    = "1.0.2"

#   set {
#     name  = "autoDiscoverAwsRegion"
#     value = "true"
#   }
#   set {
#     name  = "autoDiscoverAwsVpcID"
#     value = "true"
#   }
#   set {
#     name  = "clusterName"
#     value = local.cluster_name
#   }
# }


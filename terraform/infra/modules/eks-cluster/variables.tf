variable "cluster-name" {
  type        = string
  description = "eks-cluster"
}

variable "subnets" {
  type  = list
  description = "vpc subnets"
}

variable "vpc_id" {
  type  = string
  description = "vpc id"
}

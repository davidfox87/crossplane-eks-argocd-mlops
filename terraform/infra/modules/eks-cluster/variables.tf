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

variable "kubernetes_version" {
  type    = string
  default = "1.21"
}

variable "role_policy_arns" {
  description = "ARNs of any policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}
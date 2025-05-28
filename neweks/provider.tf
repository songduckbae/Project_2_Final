provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}


# provider "kubernetes" {
#   alias                  = "eks"
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# provider "helm" {
#   alias = "eks"
#   kubernetes {
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }

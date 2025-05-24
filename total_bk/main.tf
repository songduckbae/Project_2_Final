# vpc 모듈 호출
module "vpc" {
  source = "./modules/vpc"
}

# eks 모듈 호출
module "eks" {
  source             = "./modules/eks"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  subnet_ids         = module.vpc.public_subnet_ids
}

# wait_for_cluster: eks 생성 후 alb 등 붙일 때까지 대기
resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${module.eks.cluster_name} --region ${var.region}"
  }
  depends_on = [module.eks]
}

# VPC 정보 조회
data "aws_vpc" "eks_vpc" {
  depends_on = [module.vpc]
  filter {
    name   = "tag:Name"
    values = ["eks-vpc"]
  }
}

# ALB 모듈 호출 (provider alias 정확히 맞춰줌)
module "alb" {
  source = "./modules/alb"

  cluster_name         = module.eks.cluster_name
  region               = var.region
  vpc_id               = data.aws_vpc.eks_vpc.id
  node_group_role_arn  = module.eks.node_group_role_arn
  oidc_provider_arn    = module.eks.oidc_provider_arn
  providers = {
    kubernetes = kubernetes.eks  
    helm       = helm.eks
  }
  depends_on = [null_resource.wait_for_cluster]
}

# k8s 리소스 모듈
module "k8s" {
  source = "./modules/k8s"
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
  depends_on = [
    module.eks,
    null_resource.wait_for_cluster,
    module.alb,
    data.aws_eks_cluster.eks,
    data.aws_eks_cluster_auth.eks
  ]
}

# karpenter 모듈
module "karpenter" {
  source = "./modules/karpenter"

  cluster_name        = module.eks.cluster_name
  cluster_endpoint    = module.eks.cluster_endpoint
  oidc_provider_arn   = module.eks.oidc_provider_arn

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
    aws        = aws
    aws.use1   = aws.use1
  }
  depends_on = [
    module.eks,
    module.alb,
    null_resource.wait_for_cluster
  ]
}

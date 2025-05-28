# 기존 VPC 참조
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["msa-vpc"]   # EC2에서 만든 VPC의 Name 태그!
  }
}

# 기존 프라이빗 서브넷들 참조 (필요시 filter 조건 조Q정)
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  # private 만 뽑으려면 tag filter 추가 (예: "Name"에 private 등)
}

# 기존 퍼블릭 서브넷들 참조
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  # public 만 뽑으려면 tag filter 추가
}

# 기존 NAT용 EIP 참조 (Public IP는 AWS 콘솔에서 확인)
data "aws_eip" "nat_eip" {
  public_ip = "3.37.223.112" # 실제 EIP의 Public IP로 변경!/ 생성된 NAT IP넣기기
}

# 기존 보안그룹(Web)
data "aws_security_group" "web_sg" {
  filter {
    name   = "group-name"
    values = ["web-sg"]
  }
  vpc_id = data.aws_vpc.existing.id
}

# 기존 보안그룹(ALB)
data "aws_security_group" "public_lb_sg" {
  filter {
    name   = "group-name"
    values = ["public-alb-sg"]
  }
  vpc_id = data.aws_vpc.existing.id
}

module "eks" {
  source             = "./modules/eks"
  vpc_id             = data.aws_vpc.existing.id
  public_subnet_ids  = data.aws_subnets.public.ids
  private_subnet_ids = data.aws_subnets.private.ids
  subnet_ids         = data.aws_subnets.public.ids
}

module "k8s" {
  source = "./modules/k8s"

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  # depends_on = [
  #   module.eks,
  #   null_resource.wait_for_cluster,
  #   data.aws_eks_cluster.eks,
  #   data.aws_eks_cluster_auth.eks
  # ]
}


#EKS 클러스터 배포 (VPC/서브넷/SG는 모두 data로 참조!)
# module "eks" {
#   source  = "terraform-aws-modules/eks/aws"
#   version = "20.8.5"

#   cluster_name    = var.eks_cluster_name
#   cluster_version = "1.29"
#   vpc_id          = data.aws_vpc.existing.id
#   subnet_ids      = data.aws_subnets.private.ids

#   cluster_endpoint_public_access       = true
#   cluster_endpoint_private_access      = true
#   cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

#   eks_managed_node_groups = {
#     default = {
#       name           = "msa-ng"
#       desired_size   = 3
#       min_size       = 3
#       max_size       = 6
#       instance_types = ["t3.medium"]
#       subnets        = data.aws_subnets.private.ids
#       security_groups = [
#         data.aws_security_group.web_sg.id
#       ]
#     }
#   }
# }

resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${module.eks.cluster_name} --region ${var.region}"
  }
  depends_on = [module.eks]
}

  module "karpenter" {
    source = "./modules/karpenter"

    cluster_name        = module.eks.cluster_name
    cluster_endpoint    = module.eks.cluster_endpoint
    oidc_provider_arn   = module.eks.oidc_provider_arn

    depends_on = [
      module.eks,
      # module.alb,
      null_resource.wait_for_cluster
    ]

    providers = {
      kubernetes = kubernetes.eks
      helm       = helm.eks
      aws       = aws
      aws.use1 = aws.use1
    }
  }

# ALB 모듈 호출
module "alb" {
  source = "./modules/alb"

  cluster_name         = module.eks.cluster_name
  region               = var.region
  vpc_id               = data.aws_vpc.existing.id
  node_group_role_arn  = module.eks.node_group_role_arn
  oidc_provider_arn    = module.eks.oidc_provider_arn
  providers = {
    kubernetes.eks = kubernetes.eks  
    helm.eks       = helm.eks
  }

  depends_on = [null_resource.wait_for_cluster]
}

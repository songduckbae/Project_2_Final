provider "aws" {
  region = "ap-northeast-2"
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = "msa-eks"
  cluster_version = "1.29"
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
      subnets        = module.vpc.private_subnet_ids
      security_groups = [
        module.vpc.web_sg_id
      ]
    }
  }

  # [옵션] 클러스터 보안그룹도 별도로 지정 가능 (없으면 자동 생성)
  # cluster_security_group_id = aws_security_group.public_lb_sg.id

  # 추가 설정은 공식 모듈 문서 참고!
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_endpoint" {
  value = module.eks.cluster_endpoint
}

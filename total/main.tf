# 기존 VPC 참조
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["msa-vpc"]   # EC2에서 만든 VPC의 Name 태그!
  }
}

# 기존 프라이빗 서브넷들 참조 (필요시 filter 조건 조정)
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
  public_ip = "52.78.101.114" # 실제 EIP의 Public IP로 변경!/ 생성된 NAT IP넣기기
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

# EKS 클러스터 배포 (VPC/서브넷/SG는 모두 data로 참조!)
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.eks_cluster_name
  cluster_version = "1.29"
  vpc_id          = data.aws_vpc.existing.id
  subnet_ids      = data.aws_subnets.private.ids

  eks_managed_node_groups = {
    default = {
      desired_size   = 2
      min_size       = 1
      max_size       = 3
      instance_types = ["t3.medium"]
      subnets        = data.aws_subnets.private.ids
      security_groups = [
        data.aws_security_group.web_sg.id
      ]
    }
  }
}

resource "null_resource" "wait_for_cluster" {
  provisioner "local-exec" {
    command = "aws eks wait cluster-active --name ${module.eks.cluster_name} --region ${var.region}"
  }
  depends_on = [module.eks]
}


# output "eks_cluster_name" {
#   value = module.eks.cluster_name
# }

# output "eks_endpoint" {
#   value = module.eks.cluster_endpoint
# }

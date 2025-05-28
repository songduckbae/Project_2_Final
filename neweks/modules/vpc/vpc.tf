# modules/vpc/data-sources.tf (EKS에서 기존 VPC/서브넷/SG 참조만)
data "aws_vpc" "existing" {
  filter {
    name   = "tag:Name"
    values = ["msa-vpc"]  # EC2 VPC 이름 또는 콘솔에서 확인한 태그
  }
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.existing.id
  # filter로 private-subnet만 뽑기 (태그이름, prefix 등 활용)
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.existing.id
}

# 보안그룹도 마찬가지로 data로 참조
data "aws_security_group" "web_sg" {
  filter {
    name   = "group-name"
    values = ["web-sg"] # EC2에서 쓴 SG 이름
  }
  vpc_id = data.aws_vpc.existing.id
}

data "aws_security_group" "public_lb_sg" {
  filter {
    name   = "group-name"
    values = ["public-alb-sg"]
  }
  vpc_id = data.aws_vpc.existing.id
}

# ... (필요한 만큼 data 선언)

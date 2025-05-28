# vpc 전체 IP 주소 범위
variable "vpc_cidr" {
  description = "CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

# vpc 이름
variable "vpc_name" {
  description = "Name"
  type        = string
  default     = "msa-vpc"
}

# 사용할 가용 영역 리스트
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

# 퍼블릭 서브넷에 할당할 CIDR 리스트
variable "public_subnet_cidrs" {
  description = "List of CIDRs for public subnets"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24", "10.10.12.0/24"]
}

# 프라이빗 서브넷에 할당할 CIDR 리스트
variable "private_subnet_cidrs" {
  description = "List of CIDRs for private subnets"
  type        = list(string)
  default     = ["10.10.20.0/24", "10.10.21.0/24", "10.10.22.0/24"]
}

# EKS 클러스터 이름
variable "eks_cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "msa-eks"
}

variable "region" {
  description = "AWS region"
  default     = "ap-northeast-2"
}
variable "eks_cluster_endpoint" {
  description = "EKS 클러스터 API 서버 endpoint"
  type        = string
  #default     = "https://dummy"
  default     = ""
}

variable "eks_cluster_ca" {
  description = "EKS 클러스터 인증서 (base64 encoded)"
  type        = string
  #default     = "ZHVtbXk="  # base64로 'dummy'
  default     = ""
}

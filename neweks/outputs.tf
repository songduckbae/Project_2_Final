output "vpc_id" {
  value = data.aws_vpc.existing.id
}

output "public_subnet_ids" {
  value = data.aws_subnets.public.ids
}

output "private_subnet_ids" {
  value = data.aws_subnets.private.ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "cluster_ca" {
  value = module.eks.cluster_ca_certificate
}

#052_2:56 현지 추가 [카펜터부분]
output "kapen-msa-node_instance_profile" {
  value = module.karpenter.kapen-msa-node_instance_profile
}
output "vpc_id" {
  value = data.aws_vpc.existing.id
}

output "private_subnet_ids" {
  value = data.aws_subnet_ids.private.ids
}

output "public_subnet_ids" {
  value = data.aws_subnet_ids.public.ids
}

output "web_sg_id" {
  value = data.aws_security_group.web_sg.id
}

output "public_lb_sg_id" {
  value = data.aws_security_group.public_lb_sg.id
}

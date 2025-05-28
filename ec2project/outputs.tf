
output "vpc_id" {
  value = aws_vpc.msa_vpc.id
}
output "public_subnet_ids" {
  value = [for s in aws_subnet.public_subnets : s.id]
}
output "private_subnet_ids" {
  value = [for s in aws_subnet.private_subnets : s.id]
}
output "public_lb_sg_id" {
  value = aws_security_group.public_lb_sg.id
}
output "private_lb_sg_id" {
  value = aws_security_group.private_lb_sg.id
}
output "web_sg_id" {
  value = aws_security_group.web_sg.id
}

output "bastion_sg_id" {
  value = aws_security_group.bastion_sg.id
}
output "alb_listener_arn" {
  value = aws_lb_listener.front_end[0].arn
  description = "ALB Listener ARN for API Gateway integration"
}
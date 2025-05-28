output "kapen-msa-controller_role_arn" {
  value = aws_iam_role.kapen-msa-controller.arn
}

output "kapen-msa-node_instance_profile" {
  value = aws_iam_instance_profile.kapen-msa-node.name
}


#두곳다 변경함 0528 3:43


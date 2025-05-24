data "aws_vpc" "msa_vpc" {
  id = var.vpc_id
}

data "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_ids)
  id = var.public_subnet_ids[count.index]
}

data "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_ids)
  id = var.private_subnet_ids[count.index]
}

# data "aws_iam_role" "code_pipeline_role" {
#   name = var.codepipeline_role_name
#   arn = var.codepipeline_role_arn
# }
#
# data "aws_iam_role" "code_build_role" {
#   name = var.codebuild_role_name
#   arn = var.codebuild_role_arn
# }
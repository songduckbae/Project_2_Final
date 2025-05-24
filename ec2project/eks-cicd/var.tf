variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "service_names" {
  type = list(string)
}

variable "codeconnection_arn" {
  description = "code connection arn"
  type        = string
}

variable "s3_cicd" {
  type = string
}

variable "codepipeline_role_name" {
  type = string
}

variable "codepipeline_role_arn" {
  type = string
}

variable "codebuild_role_name" {
  type = string
}

variable "codebuild_role_arn" {
  type = string
}
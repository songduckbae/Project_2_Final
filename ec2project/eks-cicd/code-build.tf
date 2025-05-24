# CICD 에서 빌드 된 애플리케이션 파일을 저장하거나 필요한 캐시 파일을 저장하는 버킷
data "aws_s3_bucket" "cicd" {
  bucket = var.s3_cicd
}

resource "aws_codebuild_project" "codebuild_projects" {
  count         = length(var.service_names)

  name          = "eks-${var.service_names[count.index]}-service"
  description   = "${var.service_names[count.index]}-service"
  build_timeout = 5
  service_role  = var.codebuild_role_arn

  artifacts {
    type     = "S3"
    location = data.aws_s3_bucket.cicd.bucket
    name     = "${var.service_names[count.index]}-service"
  }

  cache {
    type     = "S3"
    location = data.aws_s3_bucket.cicd.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "eks-cicd-group"
      stream_name = "${var.service_names[count.index]}-service-stream"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/seminchoi/sample-codes.git"
    git_clone_depth = 1
  }

  source_version = "eks-${var.service_names[count.index]}"

  vpc_config {
    vpc_id = data.aws_vpc.msa_vpc.id

    subnets = [for subnet_id in var.private_subnet_ids : subnet_id]

    security_group_ids = [aws_security_group.codebuild_sg.id]
  }

  tags = {
    Environment = "build"
  }
}

resource "aws_security_group" "codebuild_sg" {
  name        = "eks-codebuild-sg"
  description = "codebuild-sg"
  vpc_id      = data.aws_vpc.msa_vpc.id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "codebuild_sg"
  }
}
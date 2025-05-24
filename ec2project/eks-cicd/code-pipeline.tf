# 각 서비스별로 CodePipeline 생성
resource "aws_codepipeline" "service_pipeline" {
  count    = length(var.service_names)
  name     = "eks-${var.service_names[count.index]}-pipeline"
  role_arn = var.codepipeline_role_arn

  pipeline_type = "V2"

  artifact_store {
    location = data.aws_s3_bucket.cicd.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.codeconnection_arn
        FullRepositoryId = "seminchoi/sample-codes"
        BranchName       = "eks-${var.service_names[count.index]}"
      }
    }
  }

  # Git Trigger 추가
  trigger {
    provider_type = "CodeStarSourceConnection"

    git_configuration {
      source_action_name = "Source"

      push {
        branches {
          includes = ["eks-${var.service_names[count.index]}"]
        }
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.codebuild_projects[count.index].name
      }
    }
  }

  # stage {
  #   name = "Deploy"
  #
  #   action {
  #     name            = "Deploy"
  #     category        = "Deploy"
  #     owner           = "AWS"
  #     provider        = "CodeDeploy"
  #     input_artifacts = ["build_output"]
  #     version         = "1"
  #
  #     configuration = {
  #       ApplicationName     = aws_codedeploy_app.service_apps[count.index].name
  #       DeploymentGroupName = aws_codedeploy_deployment_group.service_deploy_groups[count.index].deployment_group_name
  #     }
  #   }
  # }
}

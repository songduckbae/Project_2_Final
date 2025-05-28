###########################################
# EKS 환경 전용 API Gateway 연동 예시 (api.tf)
###########################################

# 1. VPC Link (API Gateway에서 ALB 접근용)
resource "aws_apigatewayv2_vpc_link" "internal_link" {
  name               = "msa-vpc-link"
  subnet_ids         = [for subnet in aws_subnet.private_subnets : subnet.id]
  security_group_ids = [aws_security_group.public_lb_sg.id]
}

# 2. API Gateway(HTTP API) 생성
resource "aws_apigatewayv2_api" "msa_http_api" {
  name          = "msa-api"
  protocol_type = "HTTP"
}

# 3. EKS Ingress Controller가 만든 ALB Listener의 ARN 사용
# (Ingress 생성 후 aws_lb_listener.front_end[0].arn에 해당)
resource "aws_apigatewayv2_integration" "eks_service_integration" {
  api_id                 = aws_apigatewayv2_api.msa_http_api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = aws_lb_listener.front_end[0].arn  # EKS Ingress Controller가 만든 ALB Listener ARN
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.internal_link.id
  integration_method     = "ANY"
  payload_format_version = "1.0"
}

# 4. 서비스별 Route 선언 (/cert, /class, /home 등)
resource "aws_apigatewayv2_route" "eks_service_routes" {
  count     = length(var.service_names)  # 예: ["cert", "class", "home"]
  api_id    = aws_apigatewayv2_api.msa_http_api.id
  route_key = "ANY /${var.service_names[count.index]}/{any+}"
  target    = "integrations/${aws_apigatewayv2_integration.eks_service_integration.id}"
}

# 5. 배포 스테이지 (기본값 $default로 지정)
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.msa_http_api.id
  name        = "$default"
  auto_deploy = true
}

###########################################
# 필요 변수 예시 (variables.tf 등)
###########################################
# variable "service_names" {
#   type    = list(string)
#   default = ["cert", "class", "home"]
# }
###########################################

# 이 파일을 eks/api.tf 등으로 저장해서 사용하세요!
# (Ingress와 연동되는 ALB Listener ARN, 서비스명 등만 환경에 맞게 맞춰주면 끝)

#!/bin/bash
set -e

#terraform apply -target=module.vpc -auto-approve
#terraform apply -target=module.eks -auto-approve


echo "[1/7] EC2 환경 출력값 추출 중..."
cd ../ec2project

VPC_ID=$(terraform output -raw vpc_id)
PRIVATE_SUBNET_IDS=$(terraform output -raw private_subnet_ids)
PUBLIC_SUBNET_IDS=$(terraform output -raw public_subnet_ids)
WEB_SG_ID=$(terraform output -raw web_sg_id)
PUBLIC_LB_SG_ID=$(terraform output -raw public_lb_sg_id)
ALB_LISTENER_ARN=$(terraform output -raw alb_listener_arn)

echo "[INFO] VPC_ID: $VPC_ID"
echo "[INFO] PRIVATE_SUBNET_IDS: $PRIVATE_SUBNET_IDS"
echo "[INFO] PUBLIC_SUBNET_IDS: $PUBLIC_SUBNET_IDS"
echo "[INFO] WEB_SG_ID: $WEB_SG_ID"
echo "[INFO] PUBLIC_LB_SG_ID: $PUBLIC_LB_SG_ID"
echo "[INFO] ALB_LISTENER_ARN: $ALB_LISTENER_ARN"

cd ../EKS

echo "[2/7] EKS terraform apply 중..."
terraform apply \
  -var="vpc_id=$VPC_ID" \
  -var="private_subnet_ids=$PRIVATE_SUBNET_IDS" \
  -var="public_subnet_ids=$PUBLIC_SUBNET_IDS" \
  -var="web_sg_id=$WEB_SG_ID" \
  -var="public_lb_sg_id=$PUBLIC_LB_SG_ID" \
  -var="alb_listener_arn=$ALB_LISTENER_ARN" \
  -auto-approve

echo "[3/7] EKS 클러스터 정보 추출 중..."
EKS_CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
EKS_CLUSTER_CA=$(terraform output -raw cluster_ca)
EKS_CLUSTER_NAME=$(terraform output -raw cluster_name)

if [[ -z "$EKS_CLUSTER_ENDPOINT" || -z "$EKS_CLUSTER_CA" || -z "$EKS_CLUSTER_NAME" ]]; then
  echo "❌ 클러스터 정보 추출 실패! (endpoint, ca, name 중 하나가 비었습니다)"
  exit 1
fi

echo "[INFO] ENDPOINT: $EKS_CLUSTER_ENDPOINT"
echo "[INFO] CA: $EKS_CLUSTER_CA"
echo "[INFO] NAME: $EKS_CLUSTER_NAME"

echo "[4/7] 클러스터 활성 대기 및 kubeconfig 설정 중..."
aws eks wait cluster-active --name "$EKS_CLUSTER_NAME" --region ap-northeast-2
aws eks update-kubeconfig --region ap-northeast-2 --name "$EKS_CLUSTER_NAME"

echo "[INFO] kubeconfig 설정 확인 중 - 노드 목록 조회"
kubectl get nodes

echo "[5/7] Karpenter Helm Chart/CRD 설치 중..."
terraform apply -target=module.karpenter.helm_release.karpenter \
  -var="eks_cluster_endpoint=$EKS_CLUSTER_ENDPOINT" \
  -var="eks_cluster_ca=$EKS_CLUSTER_CA" \
  -var="eks_cluster_name=$EKS_CLUSTER_NAME" \
  -auto-approve

echo "⏳ Karpenter CRD 등록 대기 중... (30초)"
sleep 30
kubectl get crd | grep karpenter

echo "[INFO] 기존 Provisioner 리소스 삭제 중 (충돌 방지)"
kubectl delete provisioner default --ignore-not-found

echo "[INFO] Provisioner 리소스 YAML 수동 적용 중..."
kubectl apply -f modules/karpenter/provisioner.yaml

echo "[6/7] 전체 리소스 최종 적용 (ALB, K8s 등)..."
terraform apply \
  -var="eks_cluster_endpoint=$EKS_CLUSTER_ENDPOINT" \
  -var="eks_cluster_ca=$EKS_CLUSTER_CA" \
  -var="eks_cluster_name=$EKS_CLUSTER_NAME" \
  -auto-approve

echo "✅ 모든 리소스가 성공적으로 배포되었습니다."
#!/bin/bash
set -e

# 1단계: VPC + EKS만 생성
echo "[1/7] VPC + EKS 클러스터 생성 중..."
terraform apply -target=module.vpc -auto-approve
terraform apply -target=module.eks -auto-approve

# 2단계: 클러스터 정보 추출
echo "[2/7] EKS 클러스터 정보 추출 중..."
export EKS_CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint)
export EKS_CLUSTER_CA=$(terraform output -raw cluster_ca)
export EKS_CLUSTER_NAME=$(terraform output -raw cluster_name)

if [[ -z "$EKS_CLUSTER_ENDPOINT" || -z "$EKS_CLUSTER_CA" || -z "$EKS_CLUSTER_NAME" ]]; then
  echo "❌ 클러스터 정보 추출 실패! (endpoint, ca, name 중 하나가 비었습니다)"
  exit 1
fi

echo "[INFO] ENDPOINT: $EKS_CLUSTER_ENDPOINT"
echo "[INFO] CA: $EKS_CLUSTER_CA"
echo "[INFO] NAME: $EKS_CLUSTER_NAME"

# 3단계: 클러스터 활성 대기 + kubeconfig 연결
echo "[3/7] 클러스터 활성화 대기 및 kubeconfig 설정 중..."
aws eks wait cluster-active --name "$EKS_CLUSTER_NAME" --region ap-northeast-2
aws eks update-kubeconfig --region ap-northeast-2 --name "$EKS_CLUSTER_NAME"

# 4단계: Karpenter Helm Chart 및 CRD만 우선 설치
echo "[4/7] Karpenter Helm Chart/CRD만 먼저 설치..."
terraform apply -target=module.karpenter.helm_release.karpenter \
  -var="eks_cluster_endpoint=$EKS_CLUSTER_ENDPOINT" \
  -var="eks_cluster_ca=$EKS_CLUSTER_CA" \
  -var="eks_cluster_name=$EKS_CLUSTER_NAME" \
  -auto-approve

# 5단계: CRD 생성 완료까지 대기
echo "⏳ Karpenter CRD 등록 대기 중... (30초)"
sleep 30
kubectl get crd | grep karpenter

# ✅ YAML로 Provisioner 수동 적용
echo "[INFO] 기존 Provisioner 리소스 삭제 중 (충돌 방지)"
kubectl delete provisioner default --ignore-not-found

echo "[INFO] Provisioner 리소스 YAML로 수동 적용 중..."
kubectl apply -f modules/karpenter/provisioner.yaml

# 6단계: 나머지 Karpenter 리소스 및 전체 리소스 적용
echo "[6/7] 전체 리소스 최종 적용 (ALB, K8s 등)..."
terraform apply \
  -var="eks_cluster_endpoint=$EKS_CLUSTER_ENDPOINT" \
  -var="eks_cluster_ca=$EKS_CLUSTER_CA" \
  -var="eks_cluster_name=$EKS_CLUSTER_NAME" \
  -auto-approve

echo "[7/7] ✅ 모든 리소스가 성공적으로 배포되었습니다."
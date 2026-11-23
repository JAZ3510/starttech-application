#!/usr/bin/env bash
# Usage: AWS_REGION=us-east-1 ./scripts/deploy-backend.sh [image-tag]
set -euo pipefail
AWS_REGION="${AWS_REGION:-us-east-1}"
REPO="starttech-backend-api"
CLUSTER="starttech-cluster"
TAG="${1:-$(git rev-parse HEAD)}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
IMAGE="${REGISTRY}/${REPO}:${TAG}"

(cd "${ROOT}/backend" && go test ./...)

aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${REGISTRY}"
docker build -t "${IMAGE}" "${ROOT}/backend"
docker push "${IMAGE}"

sed -i.bak "s|image: .*starttech-backend-api.*|image: ${IMAGE}|" "${ROOT}/k8s/deployment.yaml" && rm -f "${ROOT}/k8s/deployment.yaml.bak"

aws eks update-kubeconfig --name "${CLUSTER}" --region "${AWS_REGION}"
kubectl apply -f "${ROOT}/k8s/"
kubectl rollout status deployment/backend-api --timeout=300s

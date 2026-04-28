#!/usr/bin/env bash
# =============================================================================
# Azure Container Apps デプロイスクリプト
#
# 前提条件:
#   - az CLI がインストール済み (`brew install azure-cli`)
#   - Docker が起動中
#   - `az login` 済み
#
# 使い方:
#   chmod +x deploy/azure-deploy.sh
#   ./deploy/azure-deploy.sh
# =============================================================================
set -euo pipefail

# ── 設定 ─────────────────────────────────────────────────────────────────────
RESOURCE_GROUP="hello-world-rg"
LOCATION="japaneast"
ACR_NAME="helloworldacr$(openssl rand -hex 4)"   # グローバル一意にするためランダムサフィックス
ENV_NAME="hello-world-env"
BACKEND_APP="hello-backend"
FRONTEND_APP="hello-frontend"
BACKEND_IMAGE="backend:latest"
FRONTEND_IMAGE="frontend:latest"
SECRET_KEY="$(openssl rand -hex 32)"             # 本番用 SECRET_KEY を生成
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log() { echo "[$(date +%H:%M:%S)] $*"; }

# ── 0. リソースプロバイダー登録 ───────────────────────────────────────────────
# Azure Container Apps / Container Registry を初めて使うサブスクリプションでは登録が必要
log "Registering required resource providers (skip if already registered)"
az provider register -n Microsoft.App --wait --output none
az provider register -n Microsoft.ContainerRegistry --wait --output none
az provider register -n Microsoft.ContainerService --wait --output none

# ── 1. リソースグループ ───────────────────────────────────────────────────────
log "Creating resource group: ${RESOURCE_GROUP}"
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none

# ── 2. Azure Container Registry ──────────────────────────────────────────────
log "Creating ACR: ${ACR_NAME}"
az acr create \
  --resource-group "${RESOURCE_GROUP}" \
  --name "${ACR_NAME}" \
  --sku Basic \
  --admin-enabled true \
  --output none

log "Logging in to ACR"
az acr login --name "${ACR_NAME}"

ACR_LOGIN_SERVER=$(az acr show \
  --name "${ACR_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query loginServer \
  --output tsv)

# ── 3. Django イメージをビルドしてプッシュ ────────────────────────────────────
log "Building Django image"
docker build \
  --platform linux/amd64 \
  -t "${ACR_LOGIN_SERVER}/${BACKEND_IMAGE}" \
  "${PROJECT_ROOT}"

log "Pushing Django image"
docker push "${ACR_LOGIN_SERVER}/${BACKEND_IMAGE}"

# ── 4. Container Apps 環境 ────────────────────────────────────────────────────
log "Creating Container Apps environment: ${ENV_NAME}"
az containerapp env create \
  --name "${ENV_NAME}" \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none

# ── 5. Django (backend) コンテナアプリをデプロイ ──────────────────────────────
log "Deploying backend Container App"
az containerapp create \
  --name "${BACKEND_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --environment "${ENV_NAME}" \
  --image "${ACR_LOGIN_SERVER}/${BACKEND_IMAGE}" \
  --registry-server "${ACR_LOGIN_SERVER}" \
  --registry-username "$(az acr credential show --name "${ACR_NAME}" --query username -o tsv)" \
  --registry-password "$(az acr credential show --name "${ACR_NAME}" --query passwords[0].value -o tsv)" \
  --ingress external \
  --target-port 8000 \
  --min-replicas 1 \
  --max-replicas 3 \
  --env-vars \
      "SECRET_KEY=${SECRET_KEY}" \
      "DEBUG=0" \
      "ALLOWED_HOSTS=*" \
      "CORS_ALLOWED_ORIGINS=placeholder" \
  --output none

BACKEND_FQDN=$(az containerapp show \
  --name "${BACKEND_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

BACKEND_URL="https://${BACKEND_FQDN}"
log "Backend URL: ${BACKEND_URL}"

# ── 6. Next.js イメージをビルド (backend URL を bake-in) ──────────────────────
log "Building Next.js image with NEXT_PUBLIC_API_BASE_URL=${BACKEND_URL}"
docker build \
  --platform linux/amd64 \
  --build-arg "NEXT_PUBLIC_API_BASE_URL=${BACKEND_URL}" \
  -t "${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE}" \
  "${PROJECT_ROOT}/frontend"

log "Pushing Next.js image"
docker push "${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE}"

# ── 7. Next.js (frontend) コンテナアプリをデプロイ ────────────────────────────
log "Deploying frontend Container App"
az containerapp create \
  --name "${FRONTEND_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --environment "${ENV_NAME}" \
  --image "${ACR_LOGIN_SERVER}/${FRONTEND_IMAGE}" \
  --registry-server "${ACR_LOGIN_SERVER}" \
  --registry-username "$(az acr credential show --name "${ACR_NAME}" --query username -o tsv)" \
  --registry-password "$(az acr credential show --name "${ACR_NAME}" --query passwords[0].value -o tsv)" \
  --ingress external \
  --target-port 3000 \
  --min-replicas 1 \
  --max-replicas 3 \
  --output none

FRONTEND_FQDN=$(az containerapp show \
  --name "${FRONTEND_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --query properties.configuration.ingress.fqdn \
  --output tsv)

FRONTEND_URL="https://${FRONTEND_FQDN}"
log "Frontend URL: ${FRONTEND_URL}"

# ── 8. Django の CORS_ALLOWED_ORIGINS を frontend URL で更新 ──────────────────
log "Updating backend CORS_ALLOWED_ORIGINS to allow frontend"
az containerapp update \
  --name "${BACKEND_APP}" \
  --resource-group "${RESOURCE_GROUP}" \
  --set-env-vars "CORS_ALLOWED_ORIGINS=${FRONTEND_URL}" \
  --output none

# ── 完了 ─────────────────────────────────────────────────────────────────────
echo ""
echo "========================================="
echo "  Deploy complete!"
echo "========================================="
echo "  Frontend : ${FRONTEND_URL}"
echo "  Backend  : ${BACKEND_URL}"
echo ""
echo "  ACR name : ${ACR_NAME}"
echo "  (リソースを削除する場合)"
echo "  az group delete --name ${RESOURCE_GROUP} --yes"
echo "========================================="

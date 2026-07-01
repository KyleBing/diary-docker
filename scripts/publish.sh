#!/usr/bin/env sh
# 构建并推送 portal、web 镜像到 Docker Hub
# 用法：./scripts/publish.sh [版本号] [dockerhub用户名] [--latest]

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(cat "$ROOT/VERSION" | tr -d '[:space:]')}"
USER="${2:-kylebing}"
LATEST=false

if [ "$3" = "--latest" ] || [ "$1" = "--latest" ]; then
  LATEST=true
fi

echo "版本: $VERSION  用户: $USER"
cd "$ROOT"

export DIARY_VERSION="$VERSION"
export DOCKERHUB_USER="$USER"

echo ">>> 构建镜像..."
docker compose build

PORTAL_IMAGE="${USER}/diary-portal:${VERSION}"
WEB_IMAGE="${USER}/diary-web:${VERSION}"

echo ">>> 推送 $PORTAL_IMAGE"
docker push "$PORTAL_IMAGE"

echo ">>> 推送 $WEB_IMAGE"
docker push "$WEB_IMAGE"

if [ "$LATEST" = true ]; then
  docker tag "$PORTAL_IMAGE" "${USER}/diary-portal:latest"
  docker tag "$WEB_IMAGE" "${USER}/diary-web:latest"
  docker push "${USER}/diary-portal:latest"
  docker push "${USER}/diary-web:latest"
  echo ">>> 已推送 latest 标签"
fi

echo "完成。他人可使用："
echo "  DIARY_VERSION=$VERSION docker compose -f docker-compose.hub.yml up -d"

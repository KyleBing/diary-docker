# 构建并推送 portal、web 镜像到 Docker Hub
# 用法：.\scripts\publish.ps1 [-Version 9.5.4] [-User kylebing] [-Latest]

param(
    [string]$Version = (Get-Content "$PSScriptRoot\..\VERSION" -Raw).Trim(),
    [string]$User = "kylebing",
    [switch]$Latest
)

$ErrorActionPreference = "Stop"
$Root = Resolve-Path "$PSScriptRoot\.."

Write-Host "版本: $Version  用户: $User"
Set-Location $Root

# 登录 Docker Hub（若未登录会提示）
docker info 2>$null | Out-Null

$env:DIARY_VERSION = $Version
$env:DOCKERHUB_USER = $User

Write-Host ">>> 构建镜像..."
docker compose build

$portalImage = "${User}/diary-portal:${Version}"
$webImage = "${User}/diary-web:${Version}"

Write-Host ">>> 推送 $portalImage"
docker push $portalImage

Write-Host ">>> 推送 $webImage"
docker push $webImage

if ($Latest) {
    docker tag $portalImage "${User}/diary-portal:latest"
    docker tag $webImage "${User}/diary-web:latest"
    docker push "${User}/diary-portal:latest"
    docker push "${User}/diary-web:latest"
    Write-Host ">>> 已推送 latest 标签"
}

Write-Host "完成。他人可使用："
Write-Host "  DIARY_VERSION=$Version docker compose -f docker-compose.hub.yml up -d"

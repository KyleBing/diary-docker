# 构建 diary-vue 前端
FROM node:20-alpine AS builder
WORKDIR /app
COPY diary-vue/package.json diary-vue/package-lock.json ./
RUN npm ci && npm install @rollup/rollup-linux-x64-musl --no-save
COPY diary-vue/ .
RUN npm run build

# Nginx 托管静态文件并反代 portal
FROM nginx:alpine
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist /usr/share/nginx/html/diary

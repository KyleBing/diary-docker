#!/bin/sh
set -e

# portal 运行时数据持久化（锁文件、上传目录），不修改项目源码
mkdir -p /app/state/upload

if [ -d /app/upload ] && [ ! -L /app/upload ]; then
    cp -a /app/upload/. /app/state/upload/ 2>/dev/null || true
fi
rm -rf /app/upload
ln -sf /app/state/upload /app/upload

# 初始化锁文件写入 /app/state，容器重建后不会误触发重复初始化
ln -sf /app/state/DATABASE_LOCK /app/DATABASE_LOCK

npm rebuild bcrypt --build-from-source
exec node ./dist/bin/portal.js

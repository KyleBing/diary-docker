# 标题日记 Docker 部署

一键部署 [标题日记](https://github.com/KyleBing/diary) 前端 + [portal](https://github.com/KyleBing/portal) 后端 + MySQL。


<img width="2577" height="1321" alt="Docker Images" src="https://github.com/user-attachments/assets/d750603b-9f6c-4685-81a6-2cd866bb22d8" />

<img width="2778" height="175" alt="Docker Container" src="https://github.com/user-attachments/assets/a5da3656-2b9f-4f10-a7e0-a4c6b193546e" />





```
diary-docker/
├── docker-compose.yml    # 编排配置
├── README_backup.md      # 数据库备份与恢复
├── docker/               # Nginx、前端构建等 Docker 文件
├── portal/               # 后端子模块
└── diary-vue/            # 前端子模块
```

## 一、前置要求

- [Docker](https://docs.docker.com/get-docker/)（含 Docker Compose）
- Git（**源码构建**时需要，用于克隆子模块）

## 二、两种方式

| 方式 | 适合谁 | 是否需要子模块 |
|------|--------|----------------|
| **Docker Hub 镜像**（推荐分享） | 只想快速跑起来 | 否 |
| **本地构建** | 开发者改代码调试 | 是 |

---

## 三、方式一：Docker Hub 镜像（推荐分享）

无需克隆子模块，只需本仓库的 compose 和 `docker/` 配置。

### 1. 克隆（不需要 `--recurse-submodules`）

```bash
git clone https://github.com/KyleBing/diary-docker.git
cd diary-docker
```

### 2. 启动指定版本

```bash
# 默认拉取 9.5.4（见 VERSION 文件）
docker compose -f docker-compose.hub.yml up -d
```

指定其他版本：

```bash
DIARY_VERSION=9.5.4 docker compose -f docker-compose.hub.yml up -d
```

### 3. 访问

```
http://localhost:8080/diary/
```

首次访问时，前端会引导完成初始化。  
默认填写的内容就能直接使用，直接下一步就行。  
完成初始化。

### Docker Hub 镜像

| 镜像 | 说明 |
|------|------|
| `kylebing/diary-portal:9.5.4` | 后端 |
| `kylebing/diary-web:9.5.4` | 前端 + Nginx |

版本号与仓库根目录 `VERSION` 文件一致。

---

## 四、方式二：本地源码构建

### 1. 克隆仓库（含子模块）

```bash
git clone --recurse-submodules https://github.com/KyleBing/diary-docker.git
cd diary-docker
```

若已克隆但未拉取子模块：

```bash
git submodule update --init --recursive
```

### 2. 启动

```bash
docker compose up -d --build
```

首次启动会拉取镜像并编译前后端，可能需要几分钟。

### 3. 访问

```
http://localhost:8080/diary/
```

> 默认端口为 **8080**，不是 80。访问时请带上 `:8080`。

默认填写的内容就能直接使用，直接下一步就行。  
完成初始化。

## 五、环境变量

复制示例文件并按需修改：

```bash
cp .env.example .env
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `WEB_PORT` | `8080` | 对外访问端口（宿主机） |
| `DB_PASSWORD` | `rootpassword` | MySQL root 密码 |
| `DIARY_VERSION` | `9.5.4` | Docker Hub 镜像版本标签 |
| `DOCKERHUB_USER` | `kylebing` | Docker Hub 用户名 |

若希望使用 `http://localhost/diary/`（不带端口号），可设置 `WEB_PORT=80`。Windows 上 80 端口可能需要管理员权限，且易与本机其他 Web 服务冲突。

## 六、常用命令

```bash
# 查看状态
docker compose ps

# 查看日志
docker compose logs -f

# 停止
docker compose down

# 停止并删除数据（会清空数据库，慎用）
docker compose down -v

# 后端更新后重建
docker compose up -d --build portal

# 前端更新后重建
docker compose up -d --build web
```

数据库备份与恢复见 [README_backup.md](./README_backup.md)。

## 七、更新子模块

### 更新 portal（后端）

```bash
git submodule update --remote portal
docker compose up -d --build portal
```

### 更新 diary-vue（前端）

```bash
git submodule update --remote diary-vue
docker compose up -d --build web
```

### 同步主仓库记录的子模块版本

```bash
git pull --recurse-submodules
```

## 八、服务说明

| 容器 | 说明 | 对外端口 |
|------|------|----------|
| `diary-mysql` | MySQL 8.0 | 无（仅内部） |
| `diary-portal` | 后端 API | 无（经 Nginx 反代） |
| `diary-web` | Nginx + 前端静态资源 | `WEB_PORT`（默认 8080） |

## 九、发布镜像到 Docker Hub（维护者）

发新版本时，先更新根目录 `VERSION` 文件，再构建推送：

```bash
# 登录 Docker Hub
docker login

# Windows
.\scripts\publish.ps1 -Latest

# Linux / macOS
chmod +x scripts/publish.sh
./scripts/publish.sh 9.5.4 kylebing --latest
```

脚本会构建并推送：

- `kylebing/diary-portal:<版本>`
- `kylebing/diary-web:<版本>`

加 `-Latest` / `--latest` 会同时推送 `latest` 标签。

也可手动：

```bash
docker compose build
docker compose push
```

## 十、局域网访问

同一局域网内的其他设备可通过本机 IP 访问：

```
http://<你的IP>:8080/diary/
```

注意防火墙需放行对应端口。仅建议在可信局域网内使用。

## 十一、子模块仓库

- 前端：[KyleBing/diary](https://github.com/KyleBing/diary) → `diary-vue/`
- 后端：[KyleBing/portal](https://github.com/KyleBing/portal) → `portal/`

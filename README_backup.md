# 数据库备份与恢复

本文说明如何备份、恢复标题日记 Docker 部署中的 **MySQL 数据**。

## 环境信息

| 项目 | 值 |
|------|-----|
| 容器名 | `diary-mysql` |
| 数据库名 | `diary` |
| 用户名 | `root` |
| 密码 | 见 `.env` 中 `DB_PASSWORD`，默认 `rootpassword` |
| 数据卷 | `mysql_data`（`docker compose down -v` 会删除，慎用） |

本地构建与 Docker Hub 镜像两种方式共用同一套 MySQL 配置，备份命令相同。

## 前置检查

在 `diary-docker` 目录执行，确认 MySQL 容器正在运行：

```bash
docker compose ps
```

应能看到 `diary-mysql` 状态为 `running` 或 `healthy`。

---

## 备份（导出）

推荐使用 `mysqldump` 导出为 `.sql` 文件，便于迁移和版本升级前留档。

### Windows（PowerShell）

```powershell
cd diary-docker

# 创建备份目录
New-Item -ItemType Directory -Force -Path .\backup

# 导出（默认密码 rootpassword）
$date = Get-Date -Format "yyyyMMdd-HHmmss"
docker exec diary-mysql mysqldump -uroot -prootpassword --single-transaction --routines --triggers diary > ".\backup\diary-$date.sql"
```

若已配置 `.env` 且修改过密码，可从环境变量读取：

```powershell
$pwd = (Get-Content .env | Where-Object { $_ -match '^DB_PASSWORD=' }) -replace 'DB_PASSWORD=', ''
$date = Get-Date -Format "yyyyMMdd-HHmmss"
docker exec diary-mysql mysqldump -uroot -p$pwd --single-transaction --routines --triggers diary > ".\backup\diary-$date.sql"
```

### Linux / macOS

```bash
cd diary-docker

mkdir -p backup

# 导出（默认密码 rootpassword）
docker exec diary-mysql mysqldump -uroot -prootpassword \
  --single-transaction --routines --triggers diary \
  > "./backup/diary-$(date +%Y%m%d-%H%M%S).sql"
```

若使用自定义密码，可先加载 `.env`：

```bash
export $(grep -v '^#' .env | xargs)
docker exec diary-mysql mysqldump -uroot -p"$DB_PASSWORD" \
  --single-transaction --routines --triggers diary \
  > "./backup/diary-$(date +%Y%m%d-%H%M%S).sql"
```

### 参数说明

| 参数 | 说明 |
|------|------|
| `--single-transaction` | 导出时不长时间锁表，适合 InnoDB |
| `--routines` | 一并导出存储过程 |
| `--triggers` | 一并导出触发器 |

导出完成后，`backup/` 目录下会生成 `diary-YYYYMMDD-HHMMSS.sql`。建议定期将该目录复制到其他磁盘或网盘。

---

## 恢复（导入）

恢复前请确认目标环境已启动且数据库已初始化（至少执行过一次 `http://localhost:8080/portal/init`）。

> **注意：** 导入会覆盖 `diary` 库中现有数据，操作前请先备份当前数据。

### Windows（PowerShell）

将 `diary-20260701-120000.sql` 替换为实际备份文件名：

```powershell
Get-Content .\backup\diary-20260701-120000.sql -Raw |
  docker exec -i diary-mysql mysql -uroot -prootpassword diary
```

### Linux / macOS

```bash
docker exec -i diary-mysql mysql -uroot -prootpassword diary \
  < ./backup/diary-20260701-120000.sql
```

导入完成后，刷新浏览器访问 `http://localhost:8080/diary/` 验证数据是否正常。

---

## 与应用内导出的区别

标题日记前端菜单支持将日记导出为 **csv / json / txt / sql**，那属于**按时间范围导出日记内容**，适合个人存档或迁移部分数据。

| 方式 | 范围 | 典型用途 |
|------|------|----------|
| **mysqldump（本文）** | 整个 `diary` 库（用户、日记、配置等） | 完整备份、迁移、升级前留档 |
| **应用内导出** | 选定时间范围内的日记 | 个人导出阅读、局部迁移 |

完整备份请使用本文的 `mysqldump` 方式。

---

## 常见问题

### 容器不存在或未运行

```bash
docker compose up -d
# 或使用 Hub 镜像
docker compose -f docker-compose.hub.yml up -d
```

### 提示 Access denied

检查 `.env` 中 `DB_PASSWORD` 是否与导出/导入命令中的密码一致。

### 备份文件很小（几 KB）

可能是容器未运行、密码错误或重定向失败。确认 `docker compose ps` 正常后重新导出，并检查 `backup/` 下文件大小是否合理。

### 误执行 `docker compose down -v`

`-v` 会删除 `mysql_data` 数据卷，数据无法通过本机简单恢复。若之前有 `.sql` 备份，可按上文「恢复」步骤重新导入。

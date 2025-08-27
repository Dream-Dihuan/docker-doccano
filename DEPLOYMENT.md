# doccano 部署指南

本指南将帮助您使用 Docker 部署 doccano 应用。

## 目录

- [系统要求](#系统要求)
- [部署方式](#部署方式)
  - [使用 Docker Compose（推荐）](#使用-docker-compose推荐)
  - [使用 run.sh 脚本](#使用-runsh-脚本)
  - [手动构建和运行](#手动构建和运行)
- [访问应用](#访问应用)
- [创建管理员账户](#创建管理员账户)
- [管理和维护](#管理和维护)
- [常见问题和解决方案](#常见问题和解决方案)

## 系统要求

- Docker >= 18.06
- Docker Compose >= 1.22

## 部署方式

### 使用 Docker Compose（推荐）

1. 确保系统已安装 Docker 和 Docker Compose
2. 进入项目根目录
3. 构建并启动服务：
   ```bash
   docker-compose up -d --build
   ```
4. 初始化数据库：
   ```bash
   docker-compose exec doccano python manage.py migrate --noinput
   ```

### 使用 run.sh 脚本

1. 赋予脚本执行权限：
   ```bash
   chmod +x run.sh
   ```
2. 运行脚本：
   ```bash
   ./run.sh
   ```
3. 脚本会自动执行构建 Docker 镜像、运行数据库迁移、创建超级用户（可选）和启动服务

### 手动构建和运行

1. 构建镜像：
   ```bash
   docker build -t doccano .
   ```
2. 运行 Redis 容器：
   ```bash
   docker run -d --name redis redis:7-alpine
   ```
3. 运行主应用：
   ```bash
   docker run -d --name doccano \
   --link redis \
   -p 2386:2386 \
   -e DJANGO_SETTINGS_MODULE=config.settings.production \
   -e STANDALONE=1 \
   -e DATABASE_URL=sqlite:///db.sqlite3 \
   -v $(pwd)/media:/app/media \
   -v $(pwd)/db.sqlite3:/app/db.sqlite3 \
   doccano
   ```
4. 运行 Celery 工作节点：
   ```bash
   docker run -d --name doccano-celery \
   --link redis \
   -e DJANGO_SETTINGS_MODULE=config.settings.production \
   -e STANDALONE=1 \
   -e DATABASE_URL=sqlite:///db.sqlite3 \
   -v $(pwd)/media:/app/media \
   -v $(pwd)/db.sqlite3:/app/db.sqlite3 \
   doccano \
   celery -A config.celery worker -l INFO -P solo -c 4 -n doccano-worker@%h -E
   ```

## 访问应用

构建和启动服务后，可以通过以下地址访问 doccano：

- Web 界面: http://localhost:2386

## 创建管理员账户

要创建管理员账户，运行以下命令：

```bash
docker-compose exec doccano python manage.py createsuperuser
```

按照提示输入用户名、邮箱和密码。

## 管理和维护

- 查看日志：
  ```bash
  docker-compose logs -f
  ```
- 停止服务：
  ```bash
  docker-compose down
  ```
- 备份数据：确保备份 `db.sqlite3` 文件和 `media/` 目录
- 更新版本：
  ```bash
  docker-compose down
  docker-compose up -d --build
  docker-compose exec doccano python manage.py migrate --noinput
  ```

## 常见问题和解决方案

### 依赖兼容性问题

在部署过程中，可能会遇到一些依赖兼容性问题，我们已经为您解决了这些问题：

1. **environs 与 marshmallow 兼容性问题**：
   - 解决方案：安装 marshmallow 版本 < 3.13.0

2. **numpy 与 pandas 兼容性问题**：
   - 解决方案：安装 numpy 版本 < 2.0.0

3. **Dockerfile 语法问题**：
   - 解决方案：使用 requirements.txt 文件安装依赖，而非 here document 方式

如果遇到其他依赖问题，请检查 Dockerfile 中的依赖安装部分，确保所有依赖版本兼容。

### 网络连接问题

如果在构建 Docker 镜像时遇到网络连接问题：

1. 确保 Docker 守护进程正在运行：
   ```bash
   docker info
   ```
2. 手动拉取基础镜像：
   ```bash
   docker pull python:3.9-slim
   ```
3. 重试构建过程

### 数据库迁移问题

如果数据库迁移失败：

1. 确保所有服务正在运行：
   ```bash
   docker-compose ps
   ```
2. 检查日志以获取更多信息：
   ```bash
   docker-compose logs doccano
   ```
3. 重新运行迁移命令：
   ```bash
   docker-compose run --rm doccano python manage.py migrate --noinput
   ```
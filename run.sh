#!/bin/bash

# Doccano Docker部署启动脚本

set -e

# 构建Docker镜像
echo "构建Doccano Docker镜像..."
docker-compose build

# 初始化数据库
echo "运行数据库迁移..."
docker-compose run --rm doccano python manage.py migrate --noinput

# 创建超级用户（可选）
echo "是否需要创建超级用户? (y/n)"
read -r create_superuser

if [ "$create_superuser" = "y" ]; then
    echo "创建超级用户..."
    docker-compose run --rm doccano python manage.py createsuperuser
fi

# 启动服务
echo "启动Doccano服务..."
docker-compose up -d

echo "Doccano已经成功启动!"
echo "访问地址: http://localhost:2386"
echo "查看日志: docker-compose logs -f"
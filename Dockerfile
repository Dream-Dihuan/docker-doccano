FROM python:3.9-slim

# 设置工作目录
WORKDIR /app

# 设置环境变量
ENV DJANGO_SETTINGS_MODULE=config.settings.production
ENV STANDALONE=1
ENV PYTHONUNBUFFERED=1
ENV DJANGO_ALLOWED_HOSTS="*"
ENV CSRF_TRUSTED_ORIGINS="https://prjlabel.scifn.co,http://localhost,http://127.0.0.1"

# 安装系统依赖
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# 复制项目文件
COPY . .

# 安装Python依赖
RUN pip install --no-cache-dir -r requirements.txt \
    && pip install --no-cache-dir doccano \
    && pip install --no-cache-dir "marshmallow<3.13.0" \
    && pip install --no-cache-dir "numpy<2.0.0"

# 收集静态文件
RUN python manage.py collectstatic --noinput

# 暴露端口
EXPOSE 2386

# 创建非root用户
RUN useradd --create-home --shell /bin/bash doccano \
    && chown -R doccano:doccano /app
USER doccano

# 启动命令
CMD ["gunicorn", "--bind=0.0.0.0:2386", "--workers=4", "--timeout=300", "--capture-output", "--log-level", "info", "config.wsgi"]
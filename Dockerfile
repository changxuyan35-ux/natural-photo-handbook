FROM python:3.12-slim

WORKDIR /app

# 安装依赖
COPY backend/requirements.txt ./backend/requirements.txt
RUN pip install --no-cache-dir -r ./backend/requirements.txt

# 复制工程源码
COPY backend/ ./backend/
COPY frontend/ ./frontend/

EXPOSE 5000

WORKDIR /app/backend
CMD ["python", "app.py"]

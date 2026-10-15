# PoseDirector (自然镜界) | AI 智能摄影导演与姿态指导平台

[![Python](https://img.shields.io/badge/Python-3.12-blue.svg)](https://www.python.org/)
[![Flask](https://img.shields.io/badge/Flask-3.0+-green.svg)](https://flask.palletsprojects.com/)
[![MediaPipe](https://img.shields.io/badge/MediaPipe-Pose-orange.svg)](https://developers.google.com/mediapipe)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> **告别僵硬摆拍与废片**。面向日常人像与旅行随拍的轻量级 AI 摄影导演平台，集成了边缘实时骨骼姿态识别、美学构图打分、语音动态导演与快门打卡成片功能。

---

## 🌟 核心特性 (Key Features)

- 📸 **实时姿态骨骼匹配 (MediaPipe Pose)**：利用 Google MediaPipe 实时提取 33 点人体骨架坐标，动态计算与标准姿态模板的匹配度。
- 🎙️ **智能语音导演 (Voice Director TTS)**：结合 Web Speech API，在检测到姿态或视线偏差时，实时语音提示“下巴微抬、单手虚托下颌线”。
- 📐 **专业构图辅助 (Composition Grid)**：内置黄金分割、九宫格三分法则辅助线，辅助拍摄者迅速找到最佳视觉交点。
- 🗄️ **持久化姿态库与拍摄记录 (SQLite Storage)**：提供 RESTful API，支持多场景姿态库管理与历史成片记录回溯。
- 🐳 **开箱即用容器化 (Docker Ready)**：支持 Docker 与 Docker Compose 一键启动前后端全栈服务。

---

## 🏗️ 架构设计 (System Architecture)

```
[ 用户摄像头视频流 ]
        │
        ├──> [ 前端 Web / Mobile Viewport ]
        │        ├──> [ MediaPipe Pose 引擎 ] ──> 33点骨骼提取与余弦匹配度计算
        │        ├──> [ Web Speech API ]   ──> 实时 AI 导演语音播报指导
        │        └──> [ HTML5 Canvas ]     ──> 姿态轮廓叠加 + EXIF 拍立得卡片生成
        │
        └──> [ 后端 Flask RESTful API (Port 5000) ]
                 ├──> [ 姿态模板管理 /api/v1/poses ]
                 ├──> [ 多模态美学分析 /api/v1/director/evaluate ]
                 └──> [ SQLite 数据存储 (posedirector.db) ]
```

---

## 📂 项目结构 (Directory Structure)

```
natural-photo-handbook/
├── backend/                  # Flask 后端服务
│   ├── app.py                # RESTful API 路由与服务入口
│   ├── database.py           # SQLite 数据库模型与模板预置脚本
│   └── requirements.txt      # 后端依赖列表
├── frontend/                 # 交互式前端界面
│   └── index.html            # 包含 MediaPipe Pose、语音合成与相机控制
├── docs/                     # 开发与部署规范文档
│   ├── api_specs.md          # 接口详细定义文档
│   └── PoseDirector_Refactoring_Roadmap.md # 深度重构白皮书
├── docker-compose.yml        # 一键容器编排
├── Dockerfile                # 后端镜像构建定义
├── README.md                 # 项目使用说明
└── LICENSE                   # MIT 开源协议
```

---

## 🚀 快速开始 (Quick Start)

### 方式一：本地 Python 环境运行

1. **安装依赖**：
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **初始化数据库并启动服务**：
   ```bash
   python app.py
   ```

3. **浏览器体验**：
   在浏览器中访问 `http://localhost:5000`，允许摄像头权限即可进入 AI 实时拍摄导演室。

---

### 方式二：Docker 一键部署

```bash
docker compose up -d
```
服务将在 `http://localhost:5000` 自动就绪。

---

## 📡 API 概览 (API Overview)

| 方法 | 路径 | 描述 |
| :--- | :--- | :--- |
| `GET` | `/api/v1/poses` | 获取场景姿态模板列表（支持按分类与难度过滤） |
| `GET` | `/api/v1/poses/<id>` | 获取特定姿态的详细骨骼关键点与专属指导语 |
| `POST` | `/api/v1/director/evaluate` | 提交关键点或画面帧，获取姿态匹配得分与指导意见 |
| `POST` | `/api/v1/records` | 保存定格照片记录与打分日志 |

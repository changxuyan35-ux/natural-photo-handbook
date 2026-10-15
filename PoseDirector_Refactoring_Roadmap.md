# PoseDirector (自然镜界) 项目完善与重构实施方案
> 深度参考开源项目 [1828703450qqcom-ux/xinyu](https://github.com/1828703450qqcom-ux/xinyu) 对 [changxuyan35-ux/natural-photo-handbook](https://github.com/changxuyan35-ux/natural-photo-handbook) 的工程化重构指引

---

## 一、 项目背景与现状对比分析

| 维度 | 参考项目：心屿 (xinyu) | 现有项目：PoseDirector (natural-photo-handbook) | 差距与重构方向 |
| :--- | :--- | :--- | :--- |
| **项目定位** | 大模型驱动的心理健康陪伴平台 (MiMo-7B) | 实时人像姿态与构图指导 AI 摄影导演 | 从 Hackathon 单页原型演进为落地全栈应用 |
| **工程架构** | **多端模块化 monorepo**<br>• `backend/` (Flask REST API)<br>• `frontend/` (Vue 3 + ECharts)<br>• `android/` (移动端原生客户端)<br>• `docs/` (多维度技术与运维文档) | **单文件轻量原型**<br>• 根目录 `index.html` (内联 JS/CSS)<br>• `prompts/director_system.md` | 重构为标准分层目录，拆分前端、后端、移动端与文档模块 |
| **AI 落地能力** | 接入真实大模型 API (Xiaomi MiMo)，含上下文与多轮会话 | 前端纯静态 Mock (硬编码匹配度 91%、写死指导文案) | 引入 [MediaPipe Pose](https://developers.google.com/mediapipe) 实时关键点检测 + 多模态视觉大模型综合打分 |
| **数据持久化** | SQLite (`emotion.db`) + 完整 ORM/数据模型 | 无数据库，无后端状态存储 | 引入 SQLite (`posedirector.db`)，存储姿态库、打分记录、用户相册 |
| **移动端适配** | 提供 Android 原生工程 | 仅桌面/移动 Web 单页 | 摄影场景强依赖手机，补齐移动端或响应式 PWA/小程序 |
| **部署与交付** | Docker 容器化一键部署 + 规范文档 | 无自动化构建、无容器配置 | 补齐 `Dockerfile`、`docker-compose.yml` 与标准 CI/CD |

---

## 二、 推荐重构工程目录结构

参考 `xinyu` 的目录划分，将 `natural-photo-handbook` 改造为规范的全栈多端项目结构：

```bash
natural-photo-handbook/
├── backend/                  # 后端 API 服务 (参考 xinyu/backend)
│   ├── app.py                # Flask 应用入口与路由分发
│   ├── config.py             # 环境变量与配置
│   ├── database.py           # SQLite 数据库连接与表初始化
│   ├── models/               # 数据模型 (User, PoseTemplate, ShootRecord)
│   ├── routes/               # API 蓝图 (poses, vision_ai, export)
│   ├── services/             # 业务逻辑 (多模态 LLM 提示词调度, TTS 语音生成)
│   ├── static/               # 静态姿态骨架参考图与素材
│   └── requirements.txt      # Python 依赖清单
├── frontend/                 # Web 端管理与体验平台 (参考 xinyu/frontend)
│   ├── src/
│   │   ├── components/       # 姿态轮廓叠加层、构图网格、相机预览组件
│   │   ├── views/            # 姿态速查库、实时导演室、历史相册
│   │   ├── utils/mediapipe/  # MediaPipe Pose 骨骼比对计算算法
│   │   └── App.vue
│   ├── package.json
│   └── vite.config.js
├── mobile/                   # 移动端客户端 (参考 xinyu/android)
│   └── (Android 原生工程或微信小程序工程，支持调用手机后置多摄)
├── docs/                     # 规范化设计与部署文档 (参考 xinyu/docs)
│   ├── architecture.md       # 系统架构设计图与技术选型
│   ├── api_specs.md          # RESTful API 接口规范
│   ├── deployment.md         # Docker 与本地部署手册
│   └── user_guide.md         # 姿态速查与拍照使用指南
├── docker-compose.yml        # 一键容器编排
├── Dockerfile                # 后端 Dockerfile
├── LICENSE                   # MIT License
└── README.md                 # 现代化 README (徽章、效果图、架构图、快速开始)
```

---

## 三、 核心模块升级实现方案

### 1. 真实姿态比对算法（替换前端硬编码 Mock）

在前端或边缘引入 `@mediapipe/camera_utils` 与 `@mediapipe/pose`，提取人体 33 个标准骨骼关键点（Landmarks），与预设标准姿态模板计算余弦相似度或关节点欧氏距离加权得分：

```javascript
// frontend/src/utils/poseMatcher.js
export function calculatePoseSimilarity(currentLandmarks, templateLandmarks) {
  // 选取主要姿态关节点：双肩(11,12)、双肘(13,14)、双手腕(15,16)、双髋(23,24)
  const keyIndices = [11, 12, 13, 14, 15, 16, 23, 24];
  let totalDistance = 0;
  let validPoints = 0;

  for (let idx of keyIndices) {
    const curr = currentLandmarks[idx];
    const temp = templateLandmarks[idx];
    if (curr && temp && curr.visibility > 0.5) {
      const dx = curr.x - temp.x;
      const dy = curr.y - temp.y;
      totalDistance += Math.sqrt(dx * dx + dy * dy);
      validPoints++;
    }
  }

  if (validPoints === 0) return 0;
  const avgDistance = totalDistance / validPoints;
  // 归一化得分：距离越小匹配度越高 (阈值 0.25 内线性缩放)
  const score = Math.max(0, Math.min(100, Math.round((1 - avgDistance / 0.25) * 100)));
  return score;
}
```

### 2. 后端架构与 RESTful API（借鉴 xinyu 的 Flask + SQLite 模式）

#### (1) 数据持久化设计 (`backend/database.py`)
```python
import sqlite3
import os

DB_PATH = os.path.join(os.path.dirname(__file__), 'posedirector.db')

def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    # 姿态模板表
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS pose_templates (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,        -- 'street', 'cafe', 'travel', 'portrait'
            gender_target TEXT,            -- 'unisex', 'female', 'male'
            difficulty TEXT,               -- 'easy', 'medium'
            svg_path TEXT NOT NULL,        -- 轮廓 SVG 路径数据
            keypoints_json TEXT,           -- 33个关键点标准坐标
            director_prompt TEXT,          -- 专属指导语模版
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    # 拍摄记录与打分日志
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS shoot_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            template_id INTEGER,
            pose_score INTEGER,
            composition_score INTEGER,
            critique_text TEXT,
            photo_metadata TEXT,           -- EXIF参数
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (template_id) REFERENCES pose_templates(id)
        )
    ''')
    conn.commit()
    conn.close()
```

#### (2) Flask 核心接口设计 (`backend/app.py`)
```python
from flask import Flask, jsonify, request
from flask_cors import CORS
import sqlite3
import os

app = Flask(__name__)
CORS(app)

DB_PATH = os.path.join(os.path.dirname(__file__), 'posedirector.db')

def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

@app.route('/api/v1/poses', methods=['GET'])
def list_poses():
    """获取姿态模板速查库，支持按分类与场景筛选"""
    category = request.args.get('category')
    conn = get_db()
    if category:
        rows = conn.execute("SELECT * FROM pose_templates WHERE category = ?", (category,)).fetchall()
    else:
        rows = conn.execute("SELECT * FROM pose_templates").fetchall()
    conn.close()
    return jsonify([dict(row) for row in rows])

@app.route('/api/v1/director/critique', methods=['POST'])
def analyze_composition():
    """多模态视觉大模型打分与语音指导建议"""
    data = request.json or {}
    image_base64 = data.get('image')
    template_id = data.get('template_id')
    
    # 接入 Vision LLM (如 MiniMax / Qwen-VL / DeepSeek)
    # 此处调用多模态接口进行美学评分与话术生成
    critique_result = {
        "pose_score": 88,
        "composition_score": 92,
        "lighting_score": 85,
        "voice_feedback": "很好！下巴稍微抬高两度，眼神看向镜头左上方30度，肩膀自然放松沉下去。",
        "rule_analysis": "已符合三分构图法，人物面部处于右上黄金交点。"
    }
    return jsonify(critique_result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
```

---

## 四、 现代化开源包装与交付规范（对标 xinyu）

1. **重构 README.md**：
   - 添加项目徽章（Python 3.12、Vue 3、MediaPipe、License MIT）。
   - 补充清晰的 **系统架构图**（摄像头输入 -> MediaPipe 边缘比对 -> 视觉大模型美学评审 -> EXIF 照片生成）。
   - 提供动图演示 (Demo GIF) 与 **一键运行指南**（本地运行与 Docker 一键部署）。
2. **规范化文档中心 (`docs/`)**：
   - 编写 `docs/api_specs.md`：详细列出所有 API 请求与响应结构。
   - 编写 `docs/deployment.md`：指导开发者使用 Docker 部署前后端。
   - 编写 `docs/pose_guide.md`：整理常见拍照场景的机位、焦段与摆姿技巧手册。
3. **引入容器化编排 (`docker-compose.yml`)**：
   - 将后端 Flask API 与前端 Vite 构建静态页面统一容器化编排，支持 `docker compose up -d` 快速启动。

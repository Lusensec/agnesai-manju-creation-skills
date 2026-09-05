# 漫剧创作 Web GUI

基于 Agnes AI 的漫剧创作可视化平台。

## 🚀 快速开始

### 1. 安装依赖

```bash
cd web
npm install
```

### 2. 启动服务

```bash
npm start
```

### 3. 访问界面

打开浏览器访问：http://localhost:3000

---

## 📁 目录结构

```
web/
├── server.js              # Express 服务器
├── package.json           # 依赖配置
├── public/                # 前端静态文件
│   ├── css/
│   │   └── style.css     # 样式文件
│   └── js/
│       ├── app.js        # 主应用
│       ├── project.js    # 项目管理
│       └── agent.js      # Agent 对话
├── api/                   # API 路由
│   ├── projects.js       # 项目管理 API
│   ├── assets.js         # 资产管理 API
│   ├── scripts.js        # 剧本管理 API
│   └── generation.js     # 生成任务 API
├── services/             # 服务层
└── templates/            # EJS 模板
    ├── layout.ejs        # 布局模板
    ├── dashboard.ejs     # 仪表盘
    └── project-new.ejs   # 新建项目
```

---

## 🎯 功能特性

### 1. 项目可视化创建
- 交互式风格选择
- 实时预览目录结构
- 自动生成项目配置

### 2. Agent 对话助手
- 右侧悬浮对话面板
- 智能建议回复
- 项目状态查询

### 3. 数据统一管理
- 直接读取 SQLite 数据库
- 资产卡片式展示
- 进度实时统计

---

## 🔧 API 接口

### 项目管理
```
GET    /api/projects          # 获取项目列表
GET    /api/projects/:id      # 获取项目详情
POST   /api/projects          # 创建项目
DELETE /api/projects/:id      # 删除项目
```

### 资产管理
```
GET    /api/assets/:projectId      # 获取资产列表
POST   /api/assets/:projectId/generate  # 生成资产
```

### 剧本管理
```
GET    /api/scripts/:projectId     # 获取剧本列表
GET    /api/scripts/:projectId/:episode  # 获取剧本内容
POST   /api/scripts/:projectId/:episode  # 保存剧本
```

### 生成任务
```
POST   /api/generation/:projectId/task      # 创建任务
POST   /api/generation/:projectId/execute   # 执行任务
GET    /api/generation/:projectId/tasks     # 获取任务列表
```

### Agent 对话
```
POST   /api/chat  # 发送消息
```

---

## 🌐 访问方式

### 方法一：直接访问
```bash
npm start
# 打开 http://localhost:3000
```

### 方法二：通过 Agent 启动
在 DSH Web GUI 中输入：
```
打开漫剧创作 Web GUI
```

---

## 📝 使用说明

1. **创建项目**：点击"新建项目"，填写配置信息
2. **查看项目**：在项目列表点击项目卡片
3. **Agent 对话**：点击右上角"与 Agent 对话"按钮
4. **管理资产**：在项目页面点击"资产库"

---

## 🔗 相关链接

- [漫剧创作 Skill](../SKILL.md)
- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)

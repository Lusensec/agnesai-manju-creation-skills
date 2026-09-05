#!/usr/bin/env node
/**
 * 漫剧创作 Web 服务器
 * 提供 Web GUI 界面和 API 接口
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const path = require('path');
const fs = require('fs');

// 导入路由
const projectsRouter = require('./api/projects');
const assetsRouter = require('./api/assets');
const scriptsRouter = require('./api/scripts');
const generationRouter = require('./api/generation');

// 创建 Express 应用
const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// 静态文件
app.use(express.static(path.join(__dirname, 'public')));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 模板引擎
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'templates'));

// ==================== 路由 ====================

// 主页
app.get('/', (req, res) => {
    res.redirect('/dashboard');
});

// 仪表盘
app.get('/dashboard', (req, res) => {
    res.render('dashboard', {
        title: '漫剧创作中心',
        projects: []
    });
});

// 项目列表
app.get('/projects', (req, res) => {
    res.render('projects', {
        title: '我的项目',
        projects: []
    });
});

// 新建项目
app.get('/projects/new', (req, res) => {
    res.render('project-new', {
        title: '新建项目',
        styles: [
            { id: '2D_chinese_guofeng', name: '2D 国风', desc: '传统水墨意境' },
            { id: '2D_flat_design', name: '2D 扁平设计', desc: '简约干净' },
            { id: '3D_anime_render', name: '3D 动漫渲染', desc: '立体渲染' },
            { id: 'realpeople_modern_city', name: '真人现代都市', desc: '真实质感' }
        ]
    });
});

// 项目详情
app.get('/projects/:id', (req, res) => {
    res.render('project-detail', {
        title: '项目详情',
        projectId: req.params.id
    });
});

// 剧本编辑
app.get('/projects/:id/script', (req, res) => {
    res.render('script-editor', {
        title: '剧本编辑',
        projectId: req.params.id
    });
});

// 资产库
app.get('/projects/:id/assets', (req, res) => {
    res.render('asset-manager', {
        title: '资产库',
        projectId: req.params.id
    });
});

// 分镜编辑器
app.get('/projects/:id/storyboard', (req, res) => {
    res.render('storyboard-editor', {
        title: '分镜编辑器',
        projectId: req.params.id
    });
});

// ==================== API 路由 ====================
app.use('/api/projects', projectsRouter);
app.use('/api/assets', assetsRouter);
app.use('/api/scripts', scriptsRouter);
app.use('/api/generation', generationRouter);

// ==================== Agent 对话 API ====================
app.post('/api/chat', async (req, res) => {
    const { message, history = [] } = req.body;
    
    // TODO: 实现 Agent 对话逻辑
    res.json({
        reply: `收到消息: ${message}`,
        suggestions: [
            '帮我查看项目状态',
            '生成新的资产',
            '查看分镜进度'
        ]
    });
});

// ==================== 启动服务器 ====================
app.listen(PORT, () => {
    console.log(`
╔════════════════════════════════════════════════════╗
║           漫剧创作 Web GUI 已启动                    ║
╠════════════════════════════════════════════════════╣
║  🌐 访问地址: http://localhost:${PORT}              ║
║  📁 项目目录: ${path.join(__dirname, '../projects')}   ║
║  🔌 API 端口: ${PORT}                               ║
╚════════════════════════════════════════════════════╝
    `);
    console.log(`\n按 Ctrl+C 停止服务器\n`);
});

module.exports = app;

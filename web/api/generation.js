/**
 * 生成任务 API
 */

const express = require('express');
const router = express.Router();
const { exec } = require('child_process');
const path = require('path');
const fs = require('fs');

// 创建生成任务
router.post('/:projectId/task', (req, res) => {
    const { projectId } = req.params;
    const { type, params } = req.body;
    
    // 任务类型：script/asset/storyboard/video
    const taskQueue = path.join(__dirname, '../../tasks', `${projectId}.json`);
    
    let tasks = [];
    if (fs.existsSync(taskQueue)) {
        tasks = JSON.parse(fs.readFileSync(taskQueue, 'utf8'));
    }
    
    const taskId = Date.now();
    tasks.push({
        id: taskId,
        type,
        params,
        status: 'pending',
        created_at: new Date().toISOString()
    });
    
    fs.writeFileSync(taskQueue, JSON.stringify(tasks, null, 2));
    
    res.json({ success: true, data: { id: taskId, status: 'pending' } });
});

// 执行任务
router.post('/:projectId/execute', (req, res) => {
    const { projectId } = req.params;
    const { type } = req.body;
    
    // TODO: 实现任务执行逻辑
    res.json({
        success: true,
        message: `开始执行 ${type} 任务`,
        task_id: Date.now()
    });
});

// 获取任务状态
router.get('/:projectId/tasks', (req, res) => {
    const taskQueue = path.join(__dirname, '../../tasks', `${req.params.projectId}.json`);
    
    if (!fs.existsSync(taskQueue)) {
        return res.json({ success: true, data: [] });
    }
    
    try {
        const tasks = JSON.parse(fs.readFileSync(taskQueue, 'utf8'));
        res.json({ success: true, data: tasks });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;

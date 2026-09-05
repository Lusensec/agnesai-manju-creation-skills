/**
 * 剧本管理 API
 */

const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// 获取剧本列表
router.get('/:projectId', (req, res) => {
    const projectId = req.params.projectId;
    const scriptDir = path.join(__dirname, '../../projects', projectId, '剧本');
    
    if (!fs.existsSync(scriptDir)) {
        return res.json({ success: true, data: [] });
    }
    
    try {
        const scripts = fs.readdirSync(scriptDir, { recursive: true })
            .filter(p => fs.statSync(path.join(scriptDir, p)).isFile() && p.endsWith('.xml'))
            .map(p => ({
                name: path.basename(p, '.xml'),
                path: p,
                size: fs.statSync(path.join(scriptDir, p)).size
            }));
        
        res.json({ success: true, data: scripts });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 获取剧本内容
router.get('/:projectId/:episode', (req, res) => {
    const { projectId, episode } = req.params;
    const scriptPath = path.join(__dirname, '../../projects', projectId, '剧本', episode, `${episode}_剧本.xml`);
    
    if (!fs.existsSync(scriptPath)) {
        return res.status(404).json({ success: false, error: '剧本不存在' });
    }
    
    try {
        const content = fs.readFileSync(scriptPath, 'utf8');
        res.json({ success: true, data: content });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 保存剧本
router.post('/:projectId/:episode', (req, res) => {
    const { projectId, episode } = req.params;
    const { content } = req.body;
    
    const scriptDir = path.join(__dirname, '../../projects', projectId, '剧本', episode);
    const scriptPath = path.join(scriptDir, `${episode}_剧本.xml`);
    
    try {
        if (!fs.existsSync(scriptDir)) {
            fs.mkdirSync(scriptDir, { recursive: true });
        }
        
        fs.writeFileSync(scriptPath, content, 'utf8');
        res.json({ success: true, message: '剧本保存成功' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

module.exports = router;

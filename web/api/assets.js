/**
 * 资产管理 API
 */

const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');

// 获取项目资产列表
router.get('/:projectId', (req, res) => {
    const projectId = req.params.projectId;
    const projectDir = path.join(__dirname, '../../projects', projectId);
    
    if (!fs.existsSync(projectDir)) {
        return res.status(404).json({ success: false, error: '项目不存在' });
    }
    
    try {
        const assets = {
            character: [],
            scene: [],
            prop: []
        };
        
        // 扫描各类型资产
        ['人物', '场景', '物品'].forEach((type, idx) => {
            const dir = path.join(projectDir, '图片资产', type);
            if (fs.existsSync(dir)) {
                const files = fs.readdirSync(dir)
                    .filter(f => f.match(/\.(png|jpg|jpeg)$/i))
                    .map(f => ({
                        name: path.basename(f, path.extname(f)),
                        file: f,
                        type: ['character', 'scene', 'prop'][idx],
                        url: `/uploads/${projectId}/图片资产/${type}/${f}`
                    }));
                assets[['character', 'scene', 'prop'][idx]] = files;
            }
        });
        
        res.json({ success: true, data: assets });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 生成资产
router.post('/:projectId/generate', (req, res) => {
    const { type, name, prompt } = req.body;
    
    res.json({
        success: true,
        message: '资产生成请求已提交',
        data: { type, name, prompt }
    });
});

module.exports = router;

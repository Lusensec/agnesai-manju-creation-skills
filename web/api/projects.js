/**
 * 项目管理 API
 */

const express = require('express');
const router = express.Router();
const path = require('path');
const fs = require('fs');
const { execSync } = require('child_process');

// 获取项目根目录
const SKILL_DIR = path.join(__dirname, '../..');
const PROJECTS_DIR = path.join(SKILL_DIR, 'projects');

// 获取所有项目列表
router.get('/', (req, res) => {
    try {
        let projects = [];
        
        if (fs.existsSync(PROJECTS_DIR)) {
            const dirs = fs.readdirSync(PROJECTS_DIR, { withFileTypes: true })
                .filter(dirent => dirent.isDirectory())
                .map(dirent => dirent.name);
            
            projects = dirs.map(name => {
                const configPath = path.join(PROJECTS_DIR, name, 'project_config.json');
                let config = {};
                
                if (fs.existsSync(configPath)) {
                    try {
                        config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
                    } catch (e) {}
                }
                
                return {
                    id: name,
                    name: config.name || name,
                    style: config.style || '未知',
                    total_episodes: config.total_episodes || 0,
                    episode_duration: config.episode_duration || 0,
                    created_at: config.created_at || '',
                    progress: calculateProgress(name)
                };
            });
        }
        
        res.json({ success: true, data: projects });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 获取单个项目详情
router.get('/:id', (req, res) => {
    const projectId = req.params.id;
    const projectDir = path.join(PROJECTS_DIR, projectId);
    
    if (!fs.existsSync(projectDir)) {
        return res.status(404).json({ success: false, error: '项目不存在' });
    }
    
    try {
        const configPath = path.join(projectDir, 'project_config.json');
        const config = fs.existsSync(configPath) 
            ? JSON.parse(fs.readFileSync(configPath, 'utf8'))
            : {};
        
        // 统计各类资产数量
        const assets = {
            character: countAssets(projectDir, '人物'),
            scene: countAssets(projectDir, '场景'),
            prop: countAssets(projectDir, '物品'),
            storyboard: countAssets(projectDir, '分镜')
        };
        
        res.json({
            success: true,
            data: {
                ...config,
                id: projectId,
                assets,
                progress: calculateProgress(projectId)
            }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 创建新项目
router.post('/', (req, res) => {
    const { name, style, total_episodes, episode_duration, platform, novel_path } = req.body;
    
    if (!name || !novel_path) {
        return res.status(400).json({ success: false, error: '项目名称和小说路径为必填项' });
    }
    
    try {
        // 调用 PowerShell 脚本创建项目
        const scriptPath = path.join(SKILL_DIR, 'scripts', 'init_project.ps1');
        const command = `powershell -ExecutionPolicy Bypass -File "${scriptPath}" -Name "${name}" -NovelPath "${novel_path}" -Style "${style}" -TotalEpisodes ${total_episodes} -EpisodeDuration ${episode_duration} -Platform "${platform}"`;
        
        execSync(command, { 
            cwd: path.dirname(scriptPath),
            stdio: 'inherit',
            timeout: 60000
        });
        
        res.json({ 
            success: true, 
            message: '项目创建成功',
            data: { name }
        });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// 删除项目
router.delete('/:id', (req, res) => {
    const projectId = req.params.id;
    const projectDir = path.join(PROJECTS_DIR, projectId);
    
    if (!fs.existsSync(projectDir)) {
        return res.status(404).json({ success: false, error: '项目不存在' });
    }
    
    try {
        fs.rmSync(projectDir, { recursive: true, force: true });
        res.json({ success: true, message: '项目已删除' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
});

// ==================== 辅助函数 ====================

function countAssets(projectDir, type) {
    const dir = path.join(projectDir, '图片资产', type);
    if (!fs.existsSync(dir)) return 0;
    return fs.readdirSync(dir).filter(f => f.match(/\.(png|jpg|jpeg)$/i)).length;
}

function calculateProgress(projectId) {
    // 简化版进度计算
    const projectDir = path.join(PROJECTS_DIR, projectId);
    let completed = 0;
    let total = 5; // 5个主要步骤
    
    if (fs.existsSync(path.join(projectDir, '剧本'))) completed++;
    if (fs.existsSync(path.join(projectDir, '资产清单', 'asset_manifest.json'))) completed++;
    if (fs.existsSync(path.join(projectDir, '分镜'))) completed++;
    if (fs.existsSync(path.join(projectDir, '导演规划'))) completed++;
    if (fs.existsSync(path.join(projectDir, '视频资产'))) completed++;
    
    return Math.round((completed / total) * 100);
}

module.exports = router;

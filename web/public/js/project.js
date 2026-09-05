/**
 * 项目管理脚本
 */

// 加载仪表盘数据
async function loadDashboard() {
    try {
        // 加载项目列表
        const projects = await fetchProjects();
        renderProjectList(projects);
        
        // 更新统计
        updateStats(projects);
    } catch (error) {
        console.error('加载数据失败:', error);
    }
}

// 加载项目列表
async function loadProjects() {
    try {
        const projects = await fetchProjects();
        renderProjectGrid(projects);
    } catch (error) {
        console.error('加载项目失败:', error);
    }
}

// 加载项目详情
async function loadProjectDetail(projectId) {
    try {
        const response = await fetch(`/api/projects/${projectId}`);
        const data = await response.json();
        
        if (data.success) {
            renderProjectDetail(data.data);
        } else {
            document.getElementById('projectDetail').innerHTML = 
                `<div class="error">加载失败: ${data.error}</div>`;
        }
    } catch (error) {
        document.getElementById('projectDetail').innerHTML = 
            `<div class="error">加载失败: ${error.message}</div>`;
    }
}

// 获取项目列表
async function fetchProjects() {
    const response = await fetch('/api/projects');
    const data = await response.json();
    return data.data || [];
}

// 渲染项目网格
function renderProjectGrid(projects) {
    const container = document.getElementById('projectGrid');
    
    if (!container) return;
    
    if (projects.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>暂无项目，点击"新建项目"开始创作</p></div>';
        return;
    }
    
    container.innerHTML = projects.map(project => `
        <div class="project-card" onclick="location.href='/projects/${project.id}'">
            <div class="project-header">
                <h4>${project.name}</h4>
                <span class="badge">${project.style}</span>
            </div>
            <div class="project-info">
                <p>集数: ${project.total_episodes} | 时长: ${project.episode_duration}分钟</p>
                <p>创建时间: ${project.created_at || '未知'}</p>
            </div>
            <div class="project-progress">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${project.progress || 0}%"></div>
                </div>
                <span>${project.progress || 0}%</span>
            </div>
        </div>
    `).join('');
}

// 渲染项目详情
function renderProjectDetail(project) {
    const container = document.getElementById('projectDetail');
    
    container.innerHTML = `
        <div class="detail-section">
            <h3>基本信息</h3>
            <table class="info-table">
                <tr><td>项目名称</td><td>${project.name}</td></tr>
                <tr><td>艺术风格</td><td>${project.style}</td></tr>
                <tr><td>总集数</td><td>${project.total_episodes}</td></tr>
                <tr><td>单集时长</td><td>${project.episode_duration} 分钟</td></tr>
                <tr><td>平台规格</td><td>${project.platform}</td></tr>
                <tr><td>创建时间</td><td>${project.created_at}</td></tr>
            </table>
        </div>
        
        <div class="detail-section">
            <h3>资产统计</h3>
            <div class="asset-stats">
                <div class="asset-item">
                    <span class="label">角色</span>
                    <span class="value">${project.assets.character || 0}</span>
                </div>
                <div class="asset-item">
                    <span class="label">场景</span>
                    <span class="value">${project.assets.scene || 0}</span>
                </div>
                <div class="asset-item">
                    <span class="label">道具</span>
                    <span class="value">${project.assets.prop || 0}</span>
                </div>
                <div class="asset-item">
                    <span class="label">分镜</span>
                    <span class="value">${project.assets.storyboard || 0}</span>
                </div>
            </div>
        </div>
        
        <div class="detail-section">
            <h3>快速操作</h3>
            <div class="action-buttons">
                <a href="/projects/${project.id}/script" class="btn">📝 编辑剧本</a>
                <a href="/projects/${project.id}/assets" class="btn">🎨 管理资产</a>
                <a href="/projects/${project.id}/storyboard" class="btn">🎬 分镜编辑</a>
            </div>
        </div>
    `;
}

// 更新统计数据
function updateStats(projects) {
    const totalProjects = document.getElementById('totalProjects');
    const totalAssets = document.getElementById('totalAssets');
    const totalScripts = document.getElementById('totalScripts');
    const totalVideos = document.getElementById('totalVideos');
    
    if (totalProjects) totalProjects.textContent = projects.length;
    
    // TODO: 从数据库获取详细统计
    if (totalAssets) totalAssets.textContent = '0';
    if (totalScripts) totalScripts.textContent = '0';
    if (totalVideos) totalVideos.textContent = '0';
}

// 创建新项目
async function createProject(formData) {
    try {
        const response = await fetch('/api/projects', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (data.success) {
            alert('项目创建成功！');
            window.location.href = `/projects/${data.data.name}`;
        } else {
            alert('创建失败: ' + data.error + '\n' + (data.stderr || ''));
        }
    } catch (error) {
        alert('创建失败: ' + error.message);
    }
}

// 页面加载时初始化
document.addEventListener('DOMContentLoaded', () => {
    if (document.getElementById('projectList')) {
        loadDashboard();
    }
    if (document.getElementById('projectGrid')) {
        loadProjects();
    }
});

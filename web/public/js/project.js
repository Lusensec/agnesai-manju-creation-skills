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

// 获取项目列表
async function fetchProjects() {
    const response = await fetch('/api/projects');
    const data = await response.json();
    return data.data || [];
}

// 渲染项目列表
function renderProjectList(projects) {
    const container = document.getElementById('projectList');
    
    if (!container) return;
    
    if (projects.length === 0) {
        container.innerHTML = '<div class="empty-state"><p>暂无项目，点击"新建项目"开始创作</p></div>';
        return;
    }
    
    container.innerHTML = projects.map(project => `
        <div class="project-card" onclick="location.href='/projects/${project.id}'">
            <div class="project-info">
                <h4>${project.name}</h4>
                <p>风格: ${project.style} | 集数: ${project.total_episodes} | 创建于: ${project.created_at}</p>
            </div>
            <div class="project-progress">
                <div class="progress-bar">
                    <div class="progress-fill" style="width: ${project.progress}%"></div>
                </div>
                <span>${project.progress}%</span>
            </div>
        </div>
    `).join('');
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
            alert('创建失败: ' + data.error);
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
});

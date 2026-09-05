/**
 * 主应用脚本
 */

// Agent 面板控制
function toggleAgent() {
    const panel = document.getElementById('agentPanel');
    panel.classList.toggle('open');
}

function openAgent() {
    const panel = document.getElementById('agentPanel');
    panel.classList.add('open');
}

// 发送消息
async function sendMessage() {
    const input = document.getElementById('agentInput');
    const message = input.value.trim();
    
    if (!message) return;
    
    // 添加用户消息
    addMessage('user', message);
    input.value = '';
    
    // 调用 API
    try {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ message })
        });
        
        const data = await response.json();
        
        // 添加 Agent 回复
        setTimeout(() => {
            addMessage('agent', data.reply);
        }, 500);
    } catch (error) {
        addMessage('agent', '抱歉，服务暂时不可用');
    }
}

function addMessage(type, text) {
    const container = document.getElementById('agentMessages');
    const messageDiv = document.createElement('div');
    messageDiv.className = `message ${type}`;
    messageDiv.innerHTML = `
        <div class="avatar">${type === 'agent' ? '🤖' : '👤'}</div>
        <div class="content">${text}</div>
    `;
    container.appendChild(messageDiv);
    container.scrollTop = container.scrollHeight;
}

function handleKeyPress(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
}

// 页面加载
document.addEventListener('DOMContentLoaded', () => {
    console.log('漫剧创作 Web GUI 已加载');
});

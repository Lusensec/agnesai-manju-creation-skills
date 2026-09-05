/**
 * Agent 对话脚本
 */

// 预设问答
const PREDEFINED_RESPONSES = {
    '状态': '当前项目状态：初始化完成，等待下一步操作。',
    '进度': '项目进度：剧本 30%、资产 0%、分镜 0%、视频 0%',
    '资产': '当前资产情况：角色 0 个，场景 0 个，道具 0 个。',
    '帮助': '我可以帮你：\n1. 查看项目状态\n2. 生成资产\n3. 创建分镜\n4. 执行视频生成',
    '创建': '请使用新建项目功能创建项目，或告诉我项目名称和小说路径。',
    '风格': '当前项目使用风格：2D 国风。可以修改项目配置更换风格。'
};

// 发送消息
async function sendMessage() {
    const input = document.getElementById('agentInput');
    const message = input.value.trim();
    
    if (!message) return;
    
    // 添加用户消息
    addMessage('user', message);
    input.value = '';
    
    // 显示思考中
    const thinkingId = addMessage('agent', '思考中...');
    
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
        
        // 移除思考消息
        document.getElementById(thinkingId)?.remove();
        
        // 添加 Agent 回复
        setTimeout(() => {
            addMessage('agent', data.reply);
            
            // 显示建议
            if (data.suggestions && data.suggestions.length > 0) {
                showSuggestions(data.suggestions);
            }
        }, 500);
    } catch (error) {
        document.getElementById(thinkingId)?.remove();
        addMessage('agent', '抱歉，服务暂时不可用');
    }
}

// 添加消息
function addMessage(type, text) {
    const container = document.getElementById('agentMessages');
    const id = 'msg-' + Date.now();
    const messageDiv = document.createElement('div');
    messageDiv.id = id;
    messageDiv.className = `message ${type}`;
    messageDiv.innerHTML = `
        <div class="avatar">${type === 'agent' ? '🤖' : '👤'}</div>
        <div class="content">${text.replace(/\n/g, '<br>')}</div>
    `;
    container.appendChild(messageDiv);
    container.scrollTop = container.scrollHeight;
    return id;
}

// 显示建议
function showSuggestions(suggestions) {
    const container = document.getElementById('agentMessages');
    const suggestionDiv = document.createElement('div');
    suggestionDiv.className = 'suggestions';
    suggestionDiv.innerHTML = suggestions.map(s => 
        `<button onclick="quickSend('${s}')">${s}</button>`
    ).join('');
    container.appendChild(suggestionDiv);
}

// 快速发送
function quickSend(text) {
    document.getElementById('agentInput').value = text;
    sendMessage();
}

// 回车发送
function handleKeyPress(event) {
    if (event.key === 'Enter') {
        sendMessage();
    }
}

// 打开/关闭面板
function toggleAgent() {
    const panel = document.getElementById('agentPanel');
    panel.classList.toggle('open');
}

function openAgent() {
    const panel = document.getElementById('agentPanel');
    panel.classList.add('open');
}

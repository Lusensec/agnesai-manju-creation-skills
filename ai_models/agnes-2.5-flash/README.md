# Agnes 2.5 Flash

Agnes 2.5 Flash 是 Agnes AI 的最新一代对话模型，具有超长上下文窗口和强大的推理能力。

## 核心特性

- **512K 上下文窗口**：支持超长文本处理
- **65.5K 最大输出**：适合生成完整剧本
- **图像理解**：支持 Vision 功能
- **工具调用**：支持 Function Calling
- **Thinking 模式**：增强推理能力

## API 端点

```
POST https://api.agnes-ai.cn/v1/chat/completions
```

## 快速开始

### 1. 配置 API Key

```bash
export AGNES_API_KEY=sk-你的实际API_Key
```

### 2. 基本对话

```bash
curl -X POST "https://api.agnes-ai.cn/v1/chat/completions" \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-2.5-flash",
    "messages": [{"role": "user", "content": "你好"}]
  }'
```

## 示例脚本

参考 `examples/` 目录中的脚本：

- `basic-chat.sh` - 基本对话
- `image-understanding.sh` - 图像理解
- `thinking-mode.sh` - Thinking 模式
- `tool-calling.sh` - 工具调用

## 使用场景

在漫剧创作中，可用于：
- 剧本编写和润色
- 故事结构分析
- 角色塑造
- 分镜脚本生成
- 艺术风格建议

## 相关文档

- [官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [平台地址](https://platform.agnes-ai.cn)

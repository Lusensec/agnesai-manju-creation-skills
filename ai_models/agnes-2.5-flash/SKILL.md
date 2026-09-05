---
name: agnes-2.5-flash
description: |
  Agnes AI 对话模型。支持 512K 上下文、图像理解、工具调用和 Thinking 模式。
  用于漫剧创作中的剧本编写、故事分析、角色塑造等对话任务。
  触发词：对话、聊天、文本生成、文本理解、vision、thinking
---

# Agnes 2.5 Flash 对话模型

## 概述

Agnes 2.5 Flash 是 Agnes AI 的最新一代对话模型，具有超长上下文窗口和强大的推理能力。

## 核心能力

| 能力 | 规格 |
|------|------|
| 上下文窗口 | 512K tokens |
| 最大输出 | 65.5K tokens |
| 图像理解 | ✅ 支持 |
| 工具调用 | ✅ 支持 |
| Thinking 模式 | ✅ 支持 |
| 流式输出 | ✅ 支持 |

## API 信息

- **端点**: `POST https://api.agnes-ai.cn/v1/chat/completions`
- **模型 ID**: `agnes-2.5-flash`
- **认证**: Bearer Token

## 使用示例

### 基本对话

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-2.5-flash",
    "messages": [
      {"role": "user", "content": "你好"}
    ]
  }'
```

### 图像理解

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-2.5-flash",
    "messages": [
      {
        "role": "user",
        "content": [
          {"type": "text", "text": "这张图片有什么特点？"},
          {"type": "image_url", "image_url": {"url": "https://example.com/image.jpg"}}
        ]
      }
    ]
  }'
```

### Thinking 模式

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/chat/completions" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-2.5-flash",
    "messages": [
      {"role": "user", "content": "请分析这个故事的结构"}
    ],
    "thinking": true
  }'
```

## 支持的参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `model` | string | ✅ | 模型名称 |
| `messages` | array | ✅ | 消息列表 |
| `temperature` | float | ❌ | 温度 (0-2) |
| `max_tokens` | int | ❌ | 最大输出 token 数 |
| `stream` | bool | ❌ | 是否流式输出 |
| `thinking` | bool | ❌ | 是否启用 Thinking 模式 |

## 应用场景

- 剧本编写和润色
- 故事结构分析
- 角色塑造和对话设计
- 分镜脚本生成
- 艺术风格建议

## 相关文档

- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [Agnes AI 平台](https://platform.agnes-ai.cn)

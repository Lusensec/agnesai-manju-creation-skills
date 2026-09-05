---
name: agnes-video-2.5-flash
description: |
  Agnes AI 视频生成模型。支持文生视频、首尾帧控制、图片参考和音频参考。
  用于漫剧创作中的视频片段生成。
  触发词：视频生成、生视频、文生视频、视频创作、video generation
---

# Agnes Video 2.5 Flash 视频生成模型

## 概述

Agnes Video 2.5 Flash 是 Agnes AI 的视频生成模型，支持多种视频生成模式。

## 核心能力

| 能力 | 说明 |
|------|------|
| 文生视频 | 根据文本描述生成视频 |
| 首尾帧控制 | 指定开头和结尾帧 |
| 图片参考 | 使用图片作为参考 |
| 音频参考 | 使用音频驱动视频 |

## API 信息

- **端点**: `POST https://api.agnes-ai.cn/v1/videos`
- **模型 ID**: `agnes-video-2.5-flash`
- **认证**: Bearer Token

## 限制说明

| 限制 | 说明 |
|------|------|
| 分辨率 | 固定 720P |
| 时长 | 4-12 秒 |
| 图片参考 | 最多 5 张 |
| 音频参考 | 最多 3 段 |
| 视频参考 | 不支持 |

## 使用示例

### 文生视频

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/videos" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-video-2.5-flash",
    "prompt": "角色从坐姿站起，走向窗边"
  }'
```

### 图片参考

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/videos" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-video-2.5-flash",
    "prompt": "角色转身面向镜头",
    "extra_body": {
      "reference_images": ["https://example.com/ref1.jpg"]
    }
  }'
```

## 应用场景

在漫剧创作中，可用于：
- 分镜视频生成
- 资产动效展示
- 过渡动画生成

## 相关文档

- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [Agnes AI 平台](https://platform.agnes-ai.cn)

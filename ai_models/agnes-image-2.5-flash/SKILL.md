---
name: agnes-image-2.5-flash
description: |
  Agnes AI 图像生成模型。支持文生图、图生图和多图合成。
  用于漫剧创作中的资产生成、分镜图生成、风格参考图等。
  触发词：生图、图像生成、文生图、图生图、图片生成、asset generation
---

# Agnes Image 2.5 Flash 图像生成模型

## 概述

Agnes Image 2.5 Flash 是 Agnes AI 最新一代图像生成模型，支持文生图、图生图和多图合成工作流。

## 核心能力

| 能力 | 说明 |
|------|------|
| 文生图 | 根据文本描述生成图像 |
| 图生图 | 基于参考图生成新图像 |
| 多图合成 | 融合多张参考图 |
| 尺寸控制 | 1K/2K/3K/4K 四档 |
| 宽高比 | 8 种可选比例 |

## API 信息

- **端点**: `POST https://api.agnes-ai.cn/v1/images/generations`
- **模型 ID**: `agnes-image-2.5-flash`
- **认证**: Bearer Token

## 支持的参数

### 基础参数

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `model` | string | ✅ | 模型名称 |
| `prompt` | string | ✅ | 图像生成指令 |
| `size` | string | ✅ | 输出尺寸：1K/2K/3K/4K |
| `ratio` | string | ❌ | 宽高比，默认 1:1 |
| `response_format` | string | ❌ | 输出格式：url 或 b64_json |

### 宽高比选项

| 值 | 说明 |
|----|------|
| `1:1` | 正方形（默认） |
| `3:4` | 竖向 3:4 |
| `4:3` | 横向 4:3 |
| `16:9` | 宽屏 16:9 |
| `9:16` | 手机竖屏 |
| `2:3` | 竖向 2:3 |
| `3:2` | 横向 3:2 |
| `21:9` | 超宽屏 |

### 输出尺寸

| Ratio | 1K | 2K | 3K | 4K |
|-------|-----|-----|-----|-----|
| `1:1` | 1024×1024 | 2048×2048 | 3072×3072 | 4096×4096 |
| `16:9` | 1312×736 | 2624×1472 | 3936×2208 | 5248×2944 |

## 使用示例

### 文生图

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/images/generations" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.5-flash",
    "prompt": "国风二次元角色设定图，男性主角，儒雅英气",
    "size": "2K",
    "ratio": "1:1",
    "extra_body": {"response_format": "url"}
  }'
```

### 图生图

```bash
curl -sS -X POST "https://api.agnes-ai.cn/v1/images/generations" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.5-flash",
    "prompt": "转换为黄昏场景",
    "size": "2K",
    "ratio": "16:9",
    "extra_body": {
      "response_format": "url",
      "image": ["https://example.com/reference.jpg"]
    }
  }'
```

## 应用场景

在漫剧创作中，可用于：
- 角色四视图设定图生成
- 场景概念图生成
- 道具特写图生成
- 分镜图生成
- 衍生资产生成（服装变体、时间变体）

## 相关文档

- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [Agnes AI 平台](https://platform.agnes-ai.cn)

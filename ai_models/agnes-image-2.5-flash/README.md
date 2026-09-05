# Agnes Image 2.5 Flash

Agnes Image 2.5 Flash 是 Agnes AI 最新一代图像生成模型，支持文生图、图生图和多图合成。

## 核心特性

- **文生图**：根据文本描述生成高质量图像
- **图生图**：基于参考图生成新图像
- **多图合成**：融合多张参考图
- **4 档尺寸**：1K / 2K / 3K / 4K
- **8 种宽高比**：满足不同构图需求

## API 端点

```
POST https://api.agnes-ai.cn/v1/images/generations
```

## 快速开始

### 1. 配置 API Key

```bash
export AGNES_API_KEY=sk-你的实际API_Key
```

### 2. 生成图像

```bash
curl -X POST "https://api.agnes-ai.cn/v1/images/generations" \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-image-2.5-flash",
    "prompt": "国风二次元角色设定图",
    "size": "2K",
    "ratio": "1:1"
  }'
```

## 示例脚本

参考 `examples/` 目录中的脚本：

- `text-to-image.sh` - 文生图
- `image-to-image.sh` - 图生图
- `multi-image-combine.sh` - 多图合成
- `text-to-image-base64.sh` - Base64 输出

## 使用场景

在漫剧创作中，可用于：
- 角色四视图设定图生成
- 场景概念图生成
- 道具特写图生成
- 分镜图生成
- 衍生资产生成

## 相关文档

- [官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [平台地址](https://platform.agnes-ai.cn)

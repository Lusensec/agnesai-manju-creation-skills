# Agnes Video 2.5 Flash

Agnes Video 2.5 Flash 是 Agnes AI 的视频生成模型，支持多种视频生成模式。

## 核心特性

- **文生视频**：根据文本描述生成视频
- **首尾帧控制**：指定开头和结尾帧
- **图片参考**：最多 5 张图片参考
- **音频参考**：最多 3 段音频驱动

## API 端点

```
POST https://api.agnes-ai.cn/v1/videos
```

## 限制

| 项目 | 限制 |
|------|------|
| 分辨率 | 固定 720P |
| 时长 | 4-12 秒 |
| 图片参考 | 最多 5 张 |
| 音频参考 | 最多 3 段 |
| 视频参考 | 不支持 |

## 快速开始

### 1. 配置 API Key

```bash
export AGNES_API_KEY=sk-你的实际API_Key
```

### 2. 生成视频

```bash
curl -X POST "https://api.agnes-ai.cn/v1/videos" \
  -H "Authorization: Bearer $AGNES_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "agnes-video-2.5-flash",
    "prompt": "角色从坐姿站起，走向窗边"
  }'
```

## 示例脚本

参考 `examples/` 目录中的脚本：

- `text-to-video.sh` - 文生视频
- `image-reference.sh` - 图片参考
- `keyframe-video.sh` - 首尾帧控制
- `audio-reference.sh` - 音频参考
- `query-video.sh` - 查询视频状态

## 使用场景

在漫剧创作中，可用于：
- 分镜视频生成
- 资产动效展示
- 过渡动画生成

## 相关文档

- [官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [平台地址](https://platform.agnes-ai.cn)

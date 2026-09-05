---
name: manju-creation
description: |
  漫剧创作全链路 Skill。基于 Agnes AI 2.5 Flash 套件，实现从小说章节到完整漫剧视频的自动化生产。
  涵盖：故事骨架搭建 → 改编策略制定 → 剧本编写 → 导演规划 → 分镜表构建 → 分镜面板写入 → 资产生成 → 视频输出。
  
  子 Skill 列表：
  - script_agent_decision (决策层)
  - script_execution_skeleton (故事骨架)
  - script_execution_adaptation (改编策略)
  - script_execution_script (剧本编写)
  - production_agent_decision (决策层)
  - production_execution_director_plan (导演规划)
  - production_execution_storyboard_table (分镜表)
  - production_execution_storyboard_panel (分镜面板)
  - production_execution_storyboard_gen (分镜图生成)
  - production_execution_derive_assets (衍生资产分析)
  - production_execution_generate_assets (衍生资产生成)
  - production_agent_supervision (监督层审核)
  - ai_models (AI生成能力)
  
  触发词：漫剧、小说改编、短剧、剧本、分镜、storyboard、导演规划、视频生成、从书到剧、写漫剧
---

# 漫剧创作全链路 Skill

## 概述

本 Skill 提供从小说文本到完整漫剧视频的端到端创作能力，整合了 Agnes AI 2.5 Flash 套件的对话、图像、视频生成能力，并引入专业影视制作流程和 SQLite 数据库管理。

| 阶段 | 子 Skill | 核心产出 |
|------|----------|----------|
| **项目初始化** | | |
| | `scripts/init_project.ps1` | 创建项目结构、初始化数据库 |
| | `scripts/asset_manager.ps1` | 资产管理、状态跟踪 |
| | `scripts/project_status.ps1` | 项目状态报告 |
| **剧本阶段** | | |
| | `agent_skills/script_agent_decision` | 需求分析、任务调度 |
| | `script_skills/script_execution_skeleton` | 故事骨架（三幕结构、人物小传、分集） |
| | `script_skills/script_execution_adaptation` | 改编策略（删减决策、世界观呈现） |
| | `script_skills/script_execution_script` | 完整剧本（场景、台词、情绪设计） |
| **制作阶段** | | |
| | `agent_skills/production_agent_decision` | 导演调度、质量管控 |
| | `production_skills/production_execution_director_plan` | 导演规划（分场、情绪、过渡） |
| | `production_skills/production_execution_storyboard_table` | 分镜表（镜头设计、景别运镜） |
| | `production_skills/production_execution_storyboard_panel` | 分镜面板（素材绑定、时长规划） |
| | `production_skills/production_execution_derive_assets` | 衍生资产分析（变身状态、时间变体） |
| | `production_skills/production_execution_generate_assets` | 衍生资产图片生成 |
| | `production_skills/production_execution_storyboard_gen` | 分镜图生成 |
| | `agent_skills/production_agent_supervision` | 质量审核（红线检查） |
| **AI生成层** | `ai_models/` | 对话、图像、视频生成 |

---

## 快速开始

### 1. 配置 API Key

复制 `.env.example` 为 `.env` 并填入 Agnes AI API Key：

```bash
cp .env.example .env
# 编辑 .env 文件
AGNES_API_KEY=sk-你的实际 API Key
```

> 获取 API Key：https://platform.agnes-ai.cn

### 2. 初始化项目

使用 PowerShell 脚本创建项目结构：

```powershell
# 基本用法
./scripts/init_project.ps1 -Name "项目名" -NovelPath "小说章节文件路径或目录"

# 完整参数
./scripts/init_project.ps1 `
  -Name "项目名" `
  -NovelPath "C:\path\to\novel" `
  -Chapters "1-3" `
  -Style "2D_chinese_guofeng" `
  -TotalEpisodes 3 `
  -EpisodeDuration 1.0 `
  -Platform "竖屏"
```

执行后创建的项目目录结构：

```
projects/项目名/
├── 小说章节/
│   ├── 第0001章_XXX.md
│   └── ...
├── 图片资产/
│   ├── 人物/
│   ├── 场景/
│   └── 物品/
├── 视频资产/
│   ├── 第01集/
│   ├── 第02集/
│   └── 第03集/
├── 剧本/
├── 分镜/
├── 导演规划/
├── 资产清单/
├── 数据库/
│   └── 项目名.db
├── project_config.json
└── README.md
```

### 3. 管理资产

使用资产管理器脚本：

```powershell
# 列出所有资产
./scripts/asset_manager.ps1 -Project "项目名" -Command list

# 查看资产状态
./scripts/asset_manager.ps1 -Project "项目名" -Command status

# 添加新资产
./scripts/asset_manager.ps1 -Project "项目名" -Command add -Type character -Name "角色名"

# 生成资产提示词
./scripts/asset_manager.ps1 -Project "项目名" -Command generate-prompt -AssetId 101
```

### 4. 查看项目状态

```powershell
./scripts/project_status.ps1 -Project "项目名"
```

### 5. 启动创作流程

输入以下指令触发漫剧创作：

```
/漫剧创作 "小说名称" 第X章 第Y章
/story-manju "小说内容路径"
```

### 6. 完整流程示意

```
小说章节
    ↓
【项目初始化】创建目录结构 → 初始化数据库 → 复制小说 → 生成配置
    ↓
【故事骨架】三幕分割 → 分集决策 → 人物小传 → 付费卡点
    ↓
【改编策略】核心原则 → 删减决策 → 世界观呈现
    ↓
【剧本编写】场景描写 → 台词创作 → 情绪设计 → 节奏把控
    ↓
【导演规划】分场处理 → 台词统计 → 情绪分析 → 场间过渡
    ↓
【分镜表构建】镜头设计 → 景别运镜 → 画面描述 → 时长分配
    ↓
【分镜面板写入】素材绑定 → 资产引用 → 提示词生成
    ↓
【资产生成】角色图片 → 场景图片 → 道具图片 → 衍生状态
    ↓
【视频生成】文生视频 → 图片参考 → 首尾帧控制
    ↓
完整漫剧视频
```

---

## 详细使用指南

### 阶段一：剧本创作

#### 1.1 故事骨架搭建 (`script_skills/script_execution_skeleton.md`)

**功能**：基于原著事件表构建故事骨架

**核心产出**：
- 故事核（一句话吸引力 + 心理级爽点 + 金手指）
- 人物小传（≤4人，五要素+代入感+反差+金手指边界）
- 三幕结构（每幕功能、覆盖章节、幕末转折）
- 分集决策（逐集展开或总览+关键集）
- 付费卡点设计（≈5个卡点，位置按比例计算）
- 股价级反转登记表（≈3个反转）

**触发词**：故事骨架、分集、三幕结构、skeleton

#### 1.2 改编策略制定 (`script_skills/script_execution_adaptation.md`)

**功能**：基于骨架制定改编原则和删减策略

**核心产出**：
- 核心改编原则（3-5条，含正面指导和负面边界）
- 主要删除决策（被删内容+原因+替代方案）
- 世界观呈现策略（关键元素出场节奏、解释度）

**触发词**：改编策略、改编决策、adaptation

#### 1.3 剧本编写 (`script_skills/script_execution_script.md`)

**功能**：逐集编写完整剧本

**核心产出**：
- 文件头（标题、时长、平台规格）
- 剧情梗概（200-300字）
- 场景段落（△描述+台词+OS/V.S.）
- 黄金单集公式（情节承接+冲突升级+价值币环+下集勾连）

**触发词**：写剧本、编剧、script

---

### 阶段二：视频制作

#### 2.1 导演规划 (`production_skills/production_execution_director_plan.md`)

**功能**：基于剧本拆分场次并分析

**核心产出**：
- 分场汇总表（台词条数、台词字数、情绪浓度）
- 逐场注意事项（情感砸点、一致性锚点、空间距离）
- 场间过渡设计（动作衔接、空镜过渡）

**触发词**：导演规划、拍摄计划、director plan

#### 2.2 分镜表构建 (`production_skills/production_execution_storyboard_table.md`)

**功能**：把剧本拆成完整分镜脚本

**核心产出**：
- 场头（场景名、参演角色）
- 片段划分（≤15秒/片段）
- 镜表（画面描述、时长、景别、运镜、台词、音效）
- 引用资产列表

**触发词**：分镜表、故事板、storyboard

#### 2.3 分镜面板写入 (`production_skills/production_execution_storyboard_panel.md`)

**功能**：将分镜表数据写入工作区

**支持模式**：
- 纯文本多参模式（不生成提示词、不生成分镜图）
- 首位帧模式（完整生成 prompt 与分镜图）

**触发词**：分镜面板、写入分镜面板、storyboard panel

#### 2.4 衍生资产分析 (`production_skills/production_execution_derive_assets.md`)

**功能**：分析剧本中的资产视觉状态变体

**提取范围**：
- 角色：变身状态（服装、变身特效、变形）
- 场景：时间变体（日景→夜景、黄昏、清晨）
- 道具：不提取

**触发词**：衍生资产、资产分析、derive asset

#### 2.5 衍生资产生成 (`production_skills/production_execution_generate_assets.md`)

**功能**：调用图像模型生成衍生资产图片

**触发词**：生成资产、asset generation

#### 2.6 分镜图生成 (`production_skills/production_execution_storyboard_gen.md`)

**功能**：调用图像模型生成分镜图片

**触发词**：分镜图、storyboard image

---

### 阶段三：AI生成能力 (ai_models/)

#### 3.1 对话模型 (`ai_models/agnes-2.5-flash/SKILL.md`)

**核心能力**：
- 512K 超长上下文
- 65.5K 最大输出
- 图像理解（Vision）
- 工具调用（Function Calling）
- Thinking 模式
- 流式输出

**API 端点**：`POST https://api.agnes-ai.cn/v1/chat/completions`

#### 3.2 图像模型 (`ai_models/agnes-image-2.5-flash/SKILL.md`)

**核心能力**：
- 文生图、图生图、多图合成
- 4 种尺寸档位（1K/2K/3K/4K）
- 8 种宽高比

**API 端点**：`POST https://api.agnes-ai.cn/v1/images/generations`

#### 3.3 视频模型 (`ai_models/agnes-video-2.5-flash/SKILL.md`)

**核心能力**：
- 文生视频、首尾帧控制、图片参考、音频参考
- 固定 720P，时长 4-12 秒
- 最多 5 张图片参考、3 段音频参考

**API 端点**：`POST https://api.agnes-ai.cn/v1/videos`

---

## 艺术风格参考

### 2D 风格

| 风格 | 适用题材 | 特点 |
|------|----------|------|
| `2D_chinese_guofeng` | 古装、仙侠、历史 | 水墨意境、飘逸灵动 |
| `2D_flat_design` | 现代、都市、职场 | 简约干净、色彩明快 |
| `2D_90s_japanese_anime` | 怀旧、青春、校园 | 经典日漫、复古滤镜 |
| `2D_mature_urban_romance` | 都市情感、成熟向 | 细腻写实、氛围浓郁 |

### 3D 风格

| 风格 | 适用题材 | 特点 |
|------|----------|------|
| `3D_anime_render` | 动漫风、奇幻 | 立体渲染、动漫质感 |
| `3D_chinese_traditional` | 国风、仙侠 | 传统元素、三维呈现 |
| `3D_clay_stopmotion` | 童话、萌宠 | 黏土质感、定格动画 |
| `3D_guofeng_cyber` | 赛博国风 | 科技+传统融合 |

### 真人风格

| 风格 | 适用题材 | 特点 |
|------|----------|------|
| `realpeople_ancient_chinese` | 古装剧 | 真实演员质感 |
| `realpeople_modern_city` | 现代都市 | 真实生活感 |
| `realpeople_urban_modern` | 职场、都市 | 现代都市氛围 |

---

## 流水线约束

### 脚本阶段约束

1. **压缩比 ≤ 40%**：改编后篇幅不超过原著 60%
2. **每集必须有集末钩子**：勾住观众看下一集
3. **黄金单集公式**：情节承接+冲突升级+价值币环+下集勾连
4. **三大密度**：情绪密度/信息密度/情节密度，每集均不能"低"
5. **股价级反转 ≈3 个**：全剧核心反转，预埋集早于揭晓集

### 制作阶段约束

1. **每个片段 ≤15 秒**：单片段时长限制
2. **长台词强制拆镜**：超过 20 字须拆成多个连续镜头
3. **台词零删改**：剧本台词必须 100% 逐字保留
4. **在场人物不消失**：未写离场的角色必须有视觉痕迹
5. **禁光影色调词**：不得出现光/影/色温/明暗等描述
6. **禁配乐**：音效列只允许环境音+动作音

### AI生成约束

1. **size 固定 720P**：视频模型仅支持 720P
2. **reference 最多 5 张图**：图片参考上限 5 张
3. **audio 最多 3 段**：音频参考上限 3 段
4. **不支持视频参考**：Flash 版本不提供视频参考功能

---

## 质量审核标准

### 剧本阶段审核

- [ ] 总集数、每集时长符合项目配置
- [ ] 前2集无付费点
- [ ] 每集有集末钩子，三幕均有幕末转折
- [ ] 章节编号与事件表一致
- [ ] 全剧股价级反转 ≈3 个
- [ ] 每集满足黄金单集公式
- [ ] 前10集 ≥10 个可剪投流素材爆点
- [ ] 大三角矛盾达高级/升级级别

### 分镜阶段审核

- [ ] 资产 ID 有效（无虚构、无越界）
- [ ] 可见角色关联完整
- [ ] 场景资产关联正确
- [ ] 父子资产选择正确
- [ ] 台词完整性（100% 逐字保留）
- [ ] 剧本覆盖度与顺序
- [ ] 片段时长合理（≤15s）
- [ ] 长台词已拆镜
- [ ] VO 音画同步
- [ ] 在场人物不消失
- [ ] 群演不抢戏
- [ ] 景别视角错开

---

## 数据库架构

### SQLite 混合方案设计

采用 SQLite 数据库 + JSON 索引文件的混合方案，平衡性能与易用性。

#### 数据库表结构

| 表名 | 说明 | 关键字段 |
|------|------|----------|
| `projects` | 项目配置 | name, style, total_episodes, episode_duration |
| `assets` | 资产主表 | type, category, name, file_path, status |
| `characters` | 角色扩展 | age, gender, role, appearance |
| `scenes` | 场景扩展 | indoor_outdoor, time_of_day, season |
| `asset_derivatives` | 衍生资产 | type, name, description |
| `scripts` | 剧本 | episode_number, title, content, status |
| `storyboards` | 分镜 | episode_number, scene_number, sequence |
| `novel_chapters` | 小说章节 | chapter_number, file_path |
| `video_clips` | 视频片段 | storyboard_id, file_path, status |
| `project_tasks` | 任务记录 | task_type, status, progress |

#### 资产索引表设计

```sql
-- 资产表核心字段
CREATE TABLE assets (
    id INTEGER PRIMARY KEY,
    project_id INTEGER,
    type TEXT,              -- character/scene/prop
    category TEXT,          -- 人物/场景/物品
    name TEXT,
    file_path TEXT,         -- 相对路径
    status TEXT,            -- pending/processing/done/error
    prompt TEXT             -- 生成提示词
);

-- 分镜表引用资产
CREATE TABLE storyboards (
    id INTEGER PRIMARY KEY,
    asset_ids TEXT,         -- 逗号分隔的资产ID列表
    episode_number INTEGER,
    scene_number INTEGER,
    sequence INTEGER
);
```

#### 查询示例

```sql
-- 查看项目资产统计
SELECT type, COUNT(*) as count, 
       SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed
FROM assets 
WHERE project_id = 1 
GROUP BY type;

-- 查看角色出场次数
SELECT a.name, COUNT(sb.id) as appearances
FROM assets a
JOIN storyboards sb ON instr(sb.asset_ids, CAST(a.id AS TEXT)) > 0
WHERE a.type = 'character'
GROUP BY a.id;

-- 查看分镜进度
SELECT episode_number, 
       COUNT(*) as total,
       SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed
FROM storyboards
GROUP BY episode_number;
```

---

## 常见问题

### Q: 如何创建新项目？
A: 使用初始化脚本：`./scripts/init_project.ps1 -Name "项目名" -NovelPath "小说路径"`

### Q: 数据库文件在哪里？
A: 每个项目目录下有 `数据库/项目名.db` 文件，可使用 DB Browser for SQLite 查看。

### Q: 如何添加新资产？
A: 使用资产管理器：`./scripts/asset_manager.ps1 -Project "项目名" -Command add -Type character -Name "角色名"`

### Q: 如何查看项目进度？
A: 运行状态报告：`./scripts/project_status.ps1 -Project "项目名"`

### Q: 支持哪些艺术风格？
A: 支持 2D 国风、2D 扁平、2D 90年代日系动漫、2D 成熟都市 romance、3D 动漫渲染、3D 国风、3D 黏土定格、3D 赛博国风、真人古风、真人现代都市等 10+ 种风格，可在项目配置中选择。

### Q: 如何修改剧本或分镜？
A: 使用"重新执行/重做"指令，决策层会根据阶段关键词自动派发对应任务。

### Q: 视频生成支持哪些模式？
A: 支持文生视频、首尾帧控制、图片参考、音频参考四种模式，可通过分镜面板的 `shouldGenerateImage` 参数控制是否生成分镜图。

### Q: API Key 是否通用？
A: 是的，使用同一个 Agnes AI API Key 即可访问所有模型（对话、图像、视频）。

---

## 相关文档

- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [Agnes AI 平台](https://platform.agnes-ai.cn)
- [故事骨架搭建 Agent](./script_skills/script_execution_skeleton.md)
- [改编策略制定 Agent](./script_skills/script_execution_adaptation.md)
- [剧本编写 Agent](./script_skills/script_execution_script.md)
- [导演规划 Agent](./production_skills/production_execution_director_plan.md)
- [分镜表构建 Agent](./production_skills/production_execution_storyboard_table.md)
- [分镜面板写入 Agent](./production_skills/production_execution_storyboard_panel.md)
- [项目初始化脚本](./scripts/init_project.ps1)
- [资产管理器](./scripts/asset_manager.ps1)
- [项目状态报告](./scripts/project_status.ps1)
- [数据库 Schema](./db/schema.sql)

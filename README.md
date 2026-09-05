# 漫剧创作 Skill 套件

基于 Agnes AI 2.5 Flash 套件，实现从小说章节到完整漫剧视频的端到端创作。

## 安装

给 Agent 安装指令：

```
请安装 Agnesai 漫剧创作 Skill：https://github.com/Lusensec/agnesai-manju-creation-skills
```

## 配置

1. 编辑环境变量文件：
```bash
cp .env.example .env
```

2. 填入 Agnes AI API Key：
```bash
AGNES_API_KEY=sk-你的实际 API Key
```

> 获取 API Key：https://platform.agnes-ai.cn

## 快速开始

### 命令行触发

```bash
# 初始化项目
./scripts/init_project.ps1 -Name "项目名" -NovelPath "小说路径"

# 管理资产
./scripts/asset_manager.ps1 -Project "项目名" -Command list

# 查看状态
./scripts/project_status.ps1 -Project "项目名"
```

### Web GUI 触发

在 DeepSeek Harness Web GUI 中输入：

```
请帮我制作漫剧：将《XXX》第X章到第Y章改编为漫剧，共Z集，每集约X分钟
```

## 完整流程

```
小说章节 → 项目初始化 → 故事骨架 → 改编策略 → 剧本编写 → 导演规划 → 分镜表 → 分镜面板 → 资产生成 → 视频输出
```

| 阶段 | Skill 文件 | 核心产出 |
|------|-----------|----------|
| 初始化 | `scripts/init_project.ps1` | 项目结构、SQLite数据库 |
| 资产 | `scripts/asset_manager.ps1` | 资产索引、状态跟踪 |
| 剧本 | `script_skills/script_execution_skeleton.md` | 故事骨架、人物小传、分集决策 |
| 剧本 | `script_skills/script_execution_adaptation.md` | 改编原则、删减决策 |
| 剧本 | `script_skills/script_execution_script.md` | 完整剧本（场景、台词、情绪） |
| 制作 | `production_skills/production_execution_director_plan.md` | 分场汇总、情绪分析、过渡设计 |
| 制作 | `production_skills/production_execution_storyboard_table.md` | 分镜表（镜头、景别、运镜） |
| 制作 | `production_skills/production_execution_storyboard_panel.md` | 分镜面板（素材绑定、提示词） |
| 制作 | `production_skills/production_execution_derive_assets.md` | 衍生资产分析 |
| 制作 | `production_skills/production_execution_generate_assets.md` | 衍生资产图片生成 |
| 制作 | `production_skills/production_execution_storyboard_gen.md` | 分镜图生成 |
| 审核 | `agent_skills/production_agent_supervision.md` | 质量审核报告 |

## 目录结构

```
manju-creation/
│
├── SKILL.md                          # 主入口文档，定义 Skill 元数据和触发词
├── README.md                         # 本文件，快速上手和技术文档
├── .env.example                      # API Key 配置模板
│
├── scripts/                          # 工具脚本目录
│   ├── init_project.ps1             # 项目初始化脚本，创建目录结构和数据库
│   ├── asset_manager.ps1            # 资产管理器，管理资产数据
│   └── project_status.ps1           # 项目状态报告，显示进度统计
│
├── db/                               # 数据库目录
│   └── schema.sql                   # SQLite 数据库 Schema 定义
│
├── script_skills/                    # 剧本阶段 Skill 文件
│   ├── script_execution_skeleton.md # 故事骨架搭建
│   ├── script_execution_adaptation.md # 改编策略制定
│   └── script_execution_script.md   # 剧本编写
│
├── production_skills/                # 制作阶段 Skill 文件
│   ├── production_execution_director_plan.md       # 导演规划
│   ├── production_execution_storyboard_table.md    # 分镜表构建
│   ├── production_execution_storyboard_panel.md    # 分镜面板写入
│   ├── production_execution_storyboard_gen.md      # 分镜图生成
│   ├── production_execution_derive_assets.md       # 衍生资产分析
│   ├── production_execution_generate_assets.md     # 衍生资产生成
│   ├── storyboard_prompt_techniques.md             # 分镜提示词技巧
│   └── storyboard_table_techniques.md              # 分镜表技巧
│
├── agent_skills/                     # Agent 决策/监督层 Skill 文件
│   ├── script_agent_decision.md           # 剧本阶段决策层
│   ├── production_agent_decision.md       # 制作阶段决策层
│   └── production_agent_supervision.md    # 质量审核监督层
│
├── art_styles/                       # 艺术风格参考
│   ├── 2D_chinese_guofeng/            # 2D 国风风格
│   │   ├── README.md                  # 风格说明
│   │   ├── prefix.md                  # 提示词前缀
│   │   ├── art_prompt/                # 艺术提示词模板
│   │   │   ├── art_character.md       # 角色提示词
│   │   │   ├── art_character_derivative.md # 角色衍生提示词
│   │   │   ├── art_scene.md           # 场景提示词
│   │   │   ├── art_scene_derivative.md  # 场景衍生提示词
│   │   │   ├── art_prop.md            # 道具提示词
│   │   │   ├── art_prop_derivative.md # 道具衍生提示词
│   │   │   └── art_storyboard_video.md # 分镜视频提示词
│   │   └── driector_skills/           # 导演技巧
│   │       ├── director_planning_style.md    # 导演规划风格
│   │       ├── director_storyboard.md        # 分镜技巧
│   │       └── director_storyboard_table_style.md # 分镜表风格
│   ├── 2D_flat_design/              # 2D 扁平设计风格
│   ├── 3D_anime_render/             # 3D 动漫渲染风格
│   └── realpeople_modern_city/      # 真人现代都市风格
│
└── ai_models/                        # AI 模型能力参考
    ├── SKILL.md                       # 模型套件总览
    ├── README.md                      # 使用指南
    ├── agnes-2.5-flash/              # 对话模型
    │   ├── SKILL.md                   # 对话模型 Skill
    │   ├── README.md                  # 使用指南
    │   └── examples/                  # 示例脚本
    ├── agnes-image-2.5-flash/        # 图像模型
    │   ├── SKILL.md                   # 图像模型 Skill
    │   ├── README.md                  # 使用指南
    │   └── examples/                  # 示例脚本
    └── agnes-video-2.5-flash/        # 视频模型
        ├── SKILL.md                   # 视频模型 Skill
        ├── README.md                  # 使用指南
        └── examples/                  # 示例脚本
```

## 项目目录结构

```
projects/
└── [项目名]/
    ├── 小说章节/           # 原著小说章节
    │   ├── 第0001章_XXX.md
    │   └── ...
    ├── 图片资产/
    │   ├── 人物/          # 角色资产图片
    │   ├── 场景/          # 场景资产图片
    │   └── 物品/          # 道具资产图片
    ├── 视频资产/
    │   ├── 第01集/        # 第1集视频片段
    │   ├── 第02集/
    │   └── 第03集/
    ├── 剧本/              # 剧本文件 (XML格式)
    ├── 分镜/              # 分镜表文件
    ├── 导演规划/          # 导演规划文档
    ├── 资产清单/          # 资产索引文件
    ├── 数据库/            # SQLite 数据库
    │   └── 项目名.db
    ├── project_config.json # 项目配置
    └── README.md          # 项目说明
```

## 数据库架构

采用 SQLite 混合方案管理项目数据：

| 表名 | 说明 |
|------|------|
| `projects` | 项目配置信息 |
| `assets` | 资产主表（角色/场景/道具） |
| `characters` | 角色扩展信息 |
| `scenes` | 场景扩展信息 |
| `scripts` | 剧本内容 |
| `storyboards` | 分镜数据 |
| `video_clips` | 视频片段 |
| `project_tasks` | 任务执行记录 |

### 常用查询

```sql
-- 查看资产统计
SELECT type, COUNT(*), SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed
FROM assets GROUP BY type;

-- 查看分镜进度
SELECT episode_number, COUNT(*), SUM(CASE WHEN status='done' THEN 1 ELSE 0 END)
FROM storyboards GROUP BY episode_number;
```

## 艺术风格

支持 10+ 种视觉风格：

### 2D 风格
- `2D_chinese_guofeng` - 中国风（古装、仙侠）
- `2D_flat_design` - 扁平设计（现代、都市）
- `2D_90s_japanese_anime` - 90年代日系动漫（怀旧、青春）
- `2D_mature_urban_romance` - 成熟都市浪漫

### 3D 风格
- `3D_anime_render` - 3D动漫渲染
- `3D_chinese_traditional` - 3D国风
- `3D_clay_stopmotion` - 黏土定格动画
- `3D_guofeng_cyber` - 赛博国风

### 真人风格
- `realpeople_ancient_chinese` - 真人古风
- `realpeople_modern_city` - 真人现代都市
- `realpeople_urban_modern` - 都市职场

## 技术规格

### 对话模型 (agnes-2.5-flash)
- 上下文窗口：512K
- 最大输出：65.5K
- 支持：图像理解、工具调用、Thinking 模式

### 图像模型 (agnes-image-2.5-flash)
- 尺寸：1K / 2K / 3K / 4K
- 宽高比：8 种可选
- 支持：文生图、图生图、多图合成

### 视频模型 (agnes-video-2.5-flash)
- 分辨率：固定 720P
- 时长：4-12 秒
- 支持：文生视频、首尾帧、图片参考(≤5)、音频参考(≤3)

## 相关文档

- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)
- [Agnes AI 平台](https://platform.agnes-ai.cn)

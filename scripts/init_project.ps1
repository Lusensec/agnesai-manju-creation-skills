#!/usr/bin/env pwsh
# 漫剧项目初始化脚本
# 用途：为漫剧创作项目创建标准目录结构和数据库
# 用法：./init_project.ps1 -Name "项目名" -NovelPath "小说路径" [可选参数]

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,                           # 项目名称
    
    [Parameter(Mandatory=$true)]
    [string]$NovelPath,                     # 小说章节文件路径或目录
    
    [string]$Chapters = "1",                # 章节范围，如 "1-3" 或 "1"
    
    [string]$Style = "2D_chinese_guofeng",  # 艺术风格
    
    [int]$TotalEpisodes = 3,                # 总集数
    
    [double]$EpisodeDuration = 1.0,         # 单集时长(分钟)
    
    [string]$Platform = "竖屏"               # 平台规格
)

# 设置编码
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 基础路径
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Join-Path $ScriptDir ".."
$ProjectsDir = Join-Path $SkillDir "projects"

# 创建项目目录
$ProjectDir = Join-Path $ProjectsDir $Name
Write-Host "📁 创建项目目录: $ProjectDir" -ForegroundColor Cyan

# 创建子目录结构
$Directories = @(
    "小说章节",
    "图片资产/人物",
    "图片资产/场景", 
    "图片资产/物品",
    "视频资产",
    "剧本",
    "分镜",
    "导演规划",
    "资产清单",
    "数据库"
)

foreach ($dir in $Directories) {
    $fullPath = Join-Path $ProjectDir $dir
    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    Write-Host "  ✓ $dir" -ForegroundColor Gray
}

# 解析章节范围
if ($Chapters -match "^(\d+)-(\d+)$") {
    $startChapter = [int]$Matches[1]
    $endChapter = [int]$Matches[2]
} else {
    $startChapter = [int]$Chapters
    $endChapter = [int]$Chapters
}

# 复制小说章节
Write-Host "`n📖 复制小说章节..." -ForegroundColor Cyan

$novelDir = Split-Path -Parent $NovelPath
if (-not (Test-Path $novelDir)) {
    Write-Host "  ✗ 错误：小说路径不存在: $novelDir" -ForegroundColor Red
    exit 1
}

$novelFiles = Get-ChildItem -Path $novelDir -Filter "*.md" -Recurse | 
    Where-Object { $_.Name -match "第\d+章" } |
    Sort-Object Name

Write-Host "  找到 $($novelFiles.Count) 个小说文件" -ForegroundColor Gray

$count = 0
foreach ($file in $novelFiles) {
    if ($file.Name -match "第(\d+)章") {
        $chapterNum = [int]$Matches[1]
        if ($chapterNum -ge $startChapter -and $chapterNum -le $endChapter) {
            $destFile = Join-Path $ProjectDir "小说章节\$($file.Name)"
            Copy-Item -Path $file.FullName -Destination $destFile -Force
            Write-Host "  ✓ $($file.Name)" -ForegroundColor Green
            $count++
        }
    }
}

if ($count -eq 0) {
    Write-Host "  ⚠ 未找到匹配的章节文件，请检查章节范围" -ForegroundColor Yellow
}

# 创建数据库
Write-Host "`n🗄 初始化数据库..." -ForegroundColor Cyan

$dbPath = Join-Path $ProjectDir "数据库\$Name.db"
$schemaPath = Join-Path $ScriptDir "..\db\schema.sql"

$sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite3) {
    Write-Host "  ⚠ 未找到 sqlite3，请安装后重新运行" -ForegroundColor Yellow
    Write-Host "  下载地址：https://www.sqlite.org/download.html" -ForegroundColor Yellow
    exit 1
}

if (Test-Path $schemaPath) {
    sqlite3 $dbPath < $schemaPath
    Write-Host "  ✓ 数据库初始化完成" -ForegroundColor Green
} else {
    Write-Host "  ✗ 错误：找不到 schema.sql 文件" -ForegroundColor Red
    exit 1
}

# 插入项目配置
$escapedName = $Name.Replace("'", "''")
$escapedStyle = $Style.Replace("'", "''")
$escapedPlatform = $Platform.Replace("'", "''")

sqlite3 $dbPath @"
INSERT INTO projects (name, style, total_episodes, episode_duration, platform)
VALUES ('$escapedName', '$escapedStyle', $TotalEpisodes, $EpisodeDuration, '$escapedPlatform');
"@

Write-Host "  ✓ 项目配置已写入数据库" -ForegroundColor Green

# 创建项目配置文件
Write-Host "`n⚙ 生成项目配置..." -ForegroundColor Cyan

$config = @{
    name = $Name
    style = $Style
    total_episodes = $TotalEpisodes
    episode_duration = $EpisodeDuration
    platform = $Platform
    chapters_range = "$startChapter-$endChapter"
    created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    assets_base_dir = "图片资产"
    videos_base_dir = "视频资产"
    scripts_base_dir = "剧本"
    storyboards_base_dir = "分镜"
    db_path = "数据库\$Name.db"
}

$configJson = $config | ConvertTo-Json -Depth 10
$configPath = Join-Path $ProjectDir "project_config.json"
$configJson | Out-File -FilePath $configPath -Encoding UTF8

Write-Host "  ✓ 项目配置已保存: project_config.json" -ForegroundColor Green

# 创建资产清单模板
Write-Host "`n📋 生成资产清单模板..." -ForegroundColor Cyan

$manifestTemplate = @{
    version = "1.0"
    project = $Name
    assets = @()
    storyboards = @()
    videos = @()
    last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$manifestJson = $manifestTemplate | ConvertTo-Json -Depth 10
$manifestPath = Join-Path $ProjectDir "资产清单\asset_manifest.json"
$manifestJson | Out-File -FilePath $manifestPath -Encoding UTF8

Write-Host "  ✓ 资产清单模板已创建" -ForegroundColor Green

# 创建 README
Write-Host "`n📝 生成项目 README..." -ForegroundColor Cyan

$readmeContent = @"
# $Name 漫剧项目

## 项目信息

| 项目 | 值 |
|------|-----|
| 名称 | $Name |
| 艺术风格 | $Style |
| 总集数 | $TotalEpisodes |
| 单集时长 | $EpisodeDuration 分钟 |
| 平台规格 | $Platform |
| 创作时间 | $(Get-Date -Format "yyyy-MM-dd") |
| 章节范围 | 第${startChapter}章 - 第${endChapter}章 |

## 目录结构

\`\`\`
$Name/
├── 小说章节/          # 原著小说章节
├── 图片资产/
│   ├── 人物/         # 角色资产图片
│   ├── 场景/         # 场景资产图片
│   └── 物品/         # 道具资产图片
├── 视频资产/          # 生成的视频片段
├── 剧本/              # 剧本文件 (XML格式)
├── 分镜/              # 分镜表文件
├── 导演规划/          # 导演规划文档
├── 资产清单/          # 资产索引文件
├── 数据库/            # SQLite 数据库
├── project_config.json # 项目配置
└── README.md          # 本文件
\`\`\`

## 快速开始

### 1. 配置 API Key
编辑 \`.env\` 文件并填入 Agnes AI API Key：
\`\`\`
AGNES_API_KEY=sk-你的实际 API Key
\`\`\`

### 2. 生成资产
使用资产管理器脚本：
\`\`\`powershell
./scripts/asset_manager.ps1 -Project "$Name" -Command list
./scripts/asset_manager.ps1 -Project "$Name" -Command add -Type character -Name "角色名"
\`\`\`

### 3. 查看项目状态
\`\`\`powershell
./scripts/project_status.ps1 -Project "$Name"
\`\`\`

## 数据库查询

```sql
-- 查看资产统计
SELECT type, COUNT(*) FROM assets GROUP BY type;

-- 查看分镜进度
SELECT episode_number, COUNT(*) FROM storyboards GROUP BY episode_number;
```

## 相关文档

- [漫剧创作 Skill 文档](../SKILL.md)
- [Agnes AI 官方文档](https://agnes-ai.cn/zh-Hans/docs)
"@

$readmePath = Join-Path $ProjectDir "README.md"
$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8

Write-Host "  ✓ 项目 README 已生成" -ForegroundColor Green

# 显示项目结构
Write-Host "`n✅ 项目初始化完成!" -ForegroundColor Green
Write-Host "`n📁 项目路径: $ProjectDir" -ForegroundColor Cyan
Write-Host "`n📊 项目结构:" -ForegroundColor Cyan

Get-ChildItem -Path $ProjectDir -Directory | ForEach-Object {
    $fileCount = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "  📁 $($_.Name)/ ($fileCount 个文件)"
}

Write-Host "`n🎬 下一步:" -ForegroundColor Yellow
Write-Host "  1. 编辑 .env 配置 API Key"
Write-Host "  2. 运行资产生成: ./scripts/asset_manager.ps1 -Project '$Name' -Command add"
Write-Host "  3. 开始创作漫剧!"

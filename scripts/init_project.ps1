#!/usr/bin/env pwsh
# 漫剧项目初始化脚本（交互式版本）
# 用途：通过交互式问答收集项目配置，创建标准目录结构和数据库
# 用法：./init_project.ps1 （无参数，交互式）

# ============================================
# 艺术风格定义
# ============================================
$ArtStyles = @(
    @{ id = "2D_chinese_guofeng";   name = "2D 国风";           desc = "传统水墨意境，飘逸灵动" },
    @{ id = "2D_flat_design";        name = "2D 扁平设计";        desc = "简约干净，明快色彩" },
    @{ id = "3D_anime_render";       name = "3D 动漫渲染";        desc = "立体渲染，动漫质感" },
    @{ id = "realpeople_modern_city";name = "真人现代都市";       desc = "真实质感，都市氛围" }
)

# ============================================
# 交互函数
# ============================================
function Show-Separator {
    param([string]$Title)
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║ $Title.PadRight(48).Substring(0,48) ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Read-Required {
    param([string]$Prompt, [string]$Default = "")
    do {
        $value = Read-Host $Prompt
        if (-not $value -and $Default) { return $Default }
        if ($value) { return $value }
        Write-Host "  ⚠ 此项为必填项" -ForegroundColor Yellow
    } while ($true)
}

function Read-Optional {
    param([string]$Prompt, [string]$Default = "")
    $value = Read-Host $Prompt
    return if ($value) { $value } else { $Default }
}

function Read-StyleChoice {
    param([array]$Styles)
    
    Write-Host "请选择艺术风格（输入序号）:" -ForegroundColor Cyan
    Write-Host ""
    for ($i = 0; $i -lt $Styles.Count; $i++) {
        $style = $Styles[$i]
        $num = $i + 1
        Write-Host "  [$num] $($style.name)" -ForegroundColor White
        Write-Host "      $($style.desc)" -ForegroundColor Gray
    }
    Write-Host ""
    
    do {
        $choice = Read-Host "请输入选项 (1-$($Styles.Count))"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Styles.Count) {
            return $Styles[[int]$choice - 1]
        }
        Write-Host "  ⚠ 请输入有效选项 (1-$($Styles.Count))" -ForegroundColor Yellow
    } while ($true)
}

function Read-NumberRange {
    param([string]$Prompt, [int]$Min = 1, [int]$Max = 100, [double]$Default = 1)
    do {
        $input = Read-Host "$Prompt (`$Min`-$Max`，默认 `$Default`)"
        if (-not $input) { return $Default }
        if ($input -match '^(\d+(\.\d+)?)$') {
            $num = [double]$Matches[1]
            if ($num -ge $Min -and $num -le $Max) { return $num }
            Write-Host "  ⚠ 请输入 $Min 到 $Max 之间的数值" -ForegroundColor Yellow
        } else {
            Write-Host "  ⚠ 请输入有效数字" -ForegroundColor Yellow
        }
    } while ($true)
}

function Read-YesNo {
    param([string]$Prompt, [bool]$Default = $true)
    $defaultStr = if ($Default) { "Y/n" } else { "y/N" }
    do {
        $input = Read-Host "$Prompt ($defaultStr)"
        if (-not $input) { return $Default }
        $lower = $input.ToLower()
        if ($lower -eq 'y' -or $lower -eq 'yes') { return $true }
        if ($lower -eq 'n' -or $lower -eq 'no') { return $false }
        Write-Host "  ⚠ 请输入 y 或 n" -ForegroundColor Yellow
    } while ($true)
}

# ============================================
# 前置检查
# ============================================
function Check-Prerequisites {
    Write-Host "`n🔍 检查运行环境..." -ForegroundColor Cyan
    
    # 检查 PowerShell 版本
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -lt 7) {
        Write-Host "  ⚠ 建议升级 PowerShell 到 7+ 版本（当前: $psVersion）" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ PowerShell 版本: $psVersion" -ForegroundColor Green
    }
    
    # 检查 API Key
    $skillDir = Join-Path $ScriptDir ".."
    $envPath = Join-Path $skillDir ".env"
    if (Test-Path $envPath) {
        $envContent = Get-Content $envPath -Raw
        if ($envContent -match 'AGNES_API_KEY=(sk-[^\s]+)') {
            Write-Host "  ✓ API Key 已配置" -ForegroundColor Green
            return $true
        }
    }
    
    Write-Host "  ⚠ 未检测到 API Key" -ForegroundColor Yellow
    Write-Host "    请编辑 .env 文件并填入 Agnes AI API Key" -ForegroundColor Gray
    Write-Host "    路径: $envPath" -ForegroundColor Gray
    Write-Host ""
    
    $continue = Read-Host "  是否继续创建项目？(y/n)"
    return $continue -eq 'y'
}

function Test-SQLite3 {
    $sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if ($sqlite3) {
        Write-Host "  ✓ sqlite3 已安装: $($sqlite3.Source)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ⚠ 未检测到 sqlite3" -ForegroundColor Yellow
        Write-Host "    数据库功能将受限，但项目仍可创建" -ForegroundColor Gray
        Write-Host "    下载地址：https://www.sqlite.org/download.html" -ForegroundColor Gray
        return $false
    }
}

# ============================================
# 收集配置
# ============================================
function Collect-Config {
    Show-Separator "第一步：项目配置"
    
    # 项目名称
    $Name = Read-Required "请输入项目名称"
    
    # 艺术风格选择
    Write-Host "`n🎨 艺术风格选择：" -ForegroundColor Cyan
    $selectedStyle = Read-StyleChoice -Styles $ArtStyles
    $Style = $selectedStyle.id
    Write-Host "  ✓ 已选择: $($selectedStyle.name) - $($selectedStyle.desc)" -ForegroundColor Green
    
    # 单集时长
    $EpisodeDuration = Read-NumberRange "单集时长（分钟）" 0.5 10 1.0
    
    # 总集数
    $TotalEpisodes = Read-NumberRange "总集数" 1 20 3
    
    # 平台规格
    Write-Host "`n📱 平台规格选择：" -ForegroundColor Cyan
    $platformChoice = Read-Host "  平台规格 (h=横屏/v=竖屏，默认横屏)"
    $Platform = if ($platformChoice -eq 'v') { "竖屏" } elseif ($platformChoice -eq 'h') { "横屏" } else { "横屏" }
    Write-Host "  ✓ 平台规格: $Platform" -ForegroundColor Green
    
    # 小说章节路径
    Write-Host "`n📖 小说章节导入：" -ForegroundColor Cyan
    $NovelPath = Read-Required "请输入小说章节文件路径或目录"
    
    # 章节范围
    $ChapterInput = Read-Optional "章节范围（如 1-3，默认 1）" "1"
    if ($ChapterInput -match "^(\d+)-(\d+)$") {
        $Chapters = $ChapterInput
    } else {
        $Chapters = $ChapterInput
    }
    
    Write-Host ""
    Write-Host "─" * 40 -ForegroundColor Gray
    Write-Host "  项目配置确认：" -ForegroundColor Yellow
    Write-Host "    项目名称: $Name" -ForegroundColor White
    Write-Host "    艺术风格: $($selectedStyle.name)" -ForegroundColor White
    Write-Host "    单集时长: $EpisodeDuration 分钟" -ForegroundColor White
    Write-Host "    总集数: $TotalEpisodes 集" -ForegroundColor White
    Write-Host "    平台规格: $Platform" -ForegroundColor White
    Write-Host "    小说路径: $NovelPath" -ForegroundColor White
    Write-Host "    章节范围: $Chapters" -ForegroundColor White
    Write-Host "─" * 40 -ForegroundColor Gray
    Write-Host ""
    
    return @{
        Name = $Name
        Style = $Style
        EpisodeDuration = $EpisodeDuration
        TotalEpisodes = $TotalEpisodes
        Platform = $Platform
        NovelPath = $NovelPath
        Chapters = $Chapters
    }
}

# ============================================
# 主流程
# ============================================
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Join-Path $ScriptDir ".."
$ProjectsDir = Join-Path $SkillDir "projects"

# 前置检查
if (-not (Check-Prerequisites)) {
    Write-Host "`n已取消项目创建" -ForegroundColor Yellow
    exit 0
}

$sqliteReady = Test-SQLite3

# 收集配置
$config = Collect-Config

# 解析章节范围
if ($config.Chapters -match "^(\d+)-(\d+)$") {
    $startChapter = [int]$config.Chapters.Split("-")[0]
    $endChapter = [int]$config.Chapters.Split("-")[1]
} else {
    $startChapter = [int]$config.Chapters
    $endChapter = [int]$config.Chapters
}

$Name = $config.Name
$Style = $config.Style
$EpisodeDuration = $config.EpisodeDuration
$TotalEpisodes = $config.TotalEpisodes
$Platform = $config.Platform
$NovelPath = $config.NovelPath

# 创建项目目录
$ProjectDir = Join-Path $ProjectsDir $Name
Write-Host "📁 创建项目目录: $ProjectDir" -ForegroundColor Cyan

# 创建子目录结构
Write-Host "`n📁 创建目录结构..." -ForegroundColor Cyan

$Directories = @(
    "小说章节",
    "图片资产/人物",
    "图片资产/场景", 
    "图片资产/物品",
    "视频资产"
)

foreach ($dir in $Directories) {
    $fullPath = Join-Path $ProjectDir $dir
    New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    Write-Host "  ✓ $dir" -ForegroundColor Gray
}

# 按总集数创建子目录
Write-Host ""
Write-Host "📁 按集数创建子目录..." -ForegroundColor Cyan

for ($i = 1; $i -le $TotalEpisodes; $i++) {
    $epNum = "$($i.ToString('00'))"
    
    # 视频资产子目录
    $videoEpDir = Join-Path $ProjectDir "视频资产/第$epNum集"
    New-Item -ItemType Directory -Path $videoEpDir -Force | Out-Null
    Write-Host "  ✓ 视频资产/第$epNum集" -ForegroundColor Gray
    
    # 剧本子目录
    $scriptEpDir = Join-Path $ProjectDir "剧本/第$epNum集"
    New-Item -ItemType Directory -Path $scriptEpDir -Force | Out-Null
    Write-Host "  ✓ 剧本/第$epNum集" -ForegroundColor Gray
    
    # 分镜子目录
    $sbEpDir = Join-Path $ProjectDir "分镜/第$epNum集"
    New-Item -ItemType Directory -Path $sbEpDir -Force | Out-Null
    Write-Host "  ✓ 分镜/第$epNum集" -ForegroundColor Gray
    
    # 导演规划子目录
    $directorEpDir = Join-Path $ProjectDir "导演规划/第$epNum集"
    New-Item -ItemType Directory -Path $directorEpDir -Force | Out-Null
    Write-Host "  ✓ 导演规划/第$epNum集" -ForegroundColor Gray
    
    # 改编计划子目录
    $adaptEpDir = Join-Path $ProjectDir "改编计划/第$epNum集"
    New-Item -ItemType Directory -Path $adaptEpDir -Force | Out-Null
    Write-Host "  ✓ 改编计划/第$epNum集" -ForegroundColor Gray
}

# 其他目录
$OtherDirs = @(
    "改编计划",
    "剧本",
    "分镜",
    "导演规划",
    "资产清单",
    "数据库"
)

foreach ($dir in $OtherDirs) {
    $fullPath = Join-Path $ProjectDir $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  ✓ $dir" -ForegroundColor Gray
    }
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

if ($sqliteReady -and (Test-Path $schemaPath)) {
    sqlite3 $dbPath < $schemaPath
    Write-Host "  ✓ 数据库初始化完成" -ForegroundColor Green
} else {
    Write-Host "  ⚠ 跳过数据库初始化（sqlite3 未安装或 schema 文件缺失）" -ForegroundColor Yellow
    New-Item -ItemType File -Path $dbPath -Force | Out-Null
}

# 插入项目配置
$escapedName = $Name.Replace("'", "''")
$escapedStyle = $Style.Replace("'", "''")
$escapedPlatform = $Platform.Replace("'", "''")

if ($sqliteReady) {
    sqlite3 $dbPath @"
INSERT INTO projects (name, style, total_episodes, episode_duration, platform)
VALUES ('$escapedName', '$escapedStyle', $TotalEpisodes, $EpisodeDuration, '$escapedPlatform');
"@
    Write-Host "  ✓ 项目配置已写入数据库" -ForegroundColor Green
}

# 创建项目配置文件
Write-Host "`n⚙ 生成项目配置..." -ForegroundColor Cyan

$configData = @{
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

$configJson = $configData | ConvertTo-Json -Depth 10
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
Write-Host "  1. 运行资产生成: ./scripts/workflow.ps1 -Project '$Name'"
Write-Host "  2. 或使用工作流: ./scripts/workflow.ps1 -Project '$Name'"

#!/usr/bin/env pwsh
# 漫剧项目状态报告
# 用途：显示漫剧项目的整体状态和进度
# 用法：./project_status.ps1 -Project "项目名"

param(
    [string]$Project
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Join-Path $ScriptDir ".."
$ProjectsDir = Join-Path $SkillDir "projects"

if (-not $Project) {
    Write-Host "错误：请指定项目名称" -ForegroundColor Red
    Write-Host "用法: ./project_status.ps1 -Project '项目名'" -ForegroundColor Yellow
    exit 1
}

$projectPath = Join-Path $ProjectsDir $Project
$dbPath = Join-Path $projectPath "数据库\$Project.db"

if (-not (Test-Path $dbPath)) {
    Write-Host "错误：数据库文件不存在: $dbPath" -ForegroundColor Red
    exit 1
}

$sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite3) {
    Write-Host "错误：未找到 sqlite3" -ForegroundColor Red
    exit 1
}

$escapedProject = $Project.Replace("'", "''")

Write-Host "`n╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         漫剧项目状态报告: $Project                   ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# 项目基本信息
Write-Host "`n📋 项目信息" -ForegroundColor Yellow
$sql = "SELECT * FROM projects WHERE name='$escapedProject'"
$result = sqlite3 -json $dbPath $sql | ConvertFrom-Json
if ($result) {
    Write-Host "  名称: $($result[0].name)"
    Write-Host "  风格: $($result[0].style)"
    Write-Host "  集数: $($result[0].total_episodes)"
    Write-Host "  单集时长: $($result[0].episode_duration) 分钟"
    Write-Host "  平台规格: $($result[0].platform)"
    Write-Host "  创建时间: $($result[0].created_at)"
}

# 资产统计
Write-Host "`n🎨 资产统计" -ForegroundColor Yellow
$sql = @"
SELECT 
    type,
    COUNT(*) as total,
    SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) as pending
FROM assets
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
GROUP BY type;
"@
$result = sqlite3 -header -column $dbPath $sql
Write-Host $result

# 剧本状态
Write-Host "`n📝 剧本状态" -ForegroundColor Yellow
$sql = @"
SELECT 
    episode_number,
    title,
    status,
    word_count,
    shot_count
FROM scripts
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
ORDER BY episode_number;
"@
$result = sqlite3 -header -column $dbPath $sql
Write-Host $result

# 分镜进度
Write-Host "`n🎬 分镜进度" -ForegroundColor Yellow
$sql = @"
SELECT 
    episode_number,
    COUNT(*) as total_shots,
    SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as progress_pct
FROM storyboards
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
GROUP BY episode_number;
"@
$result = sqlite3 -header -column $dbPath $sql
Write-Host $result

# 视频进度
Write-Host "`n🎥 视频进度" -ForegroundColor Yellow
$sql = @"
SELECT 
    episode_number,
    COUNT(*) as total_clips,
    SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed,
    ROUND(SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as progress_pct
FROM video_clips
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
GROUP BY episode_number;
"@
$result = sqlite3 -header -column $dbPath $sql
Write-Host $result

# 任务状态
Write-Host "`n📦 任务状态" -ForegroundColor Yellow
$sql = @"
SELECT 
    task_type,
    status,
    COUNT(*) as count
FROM project_tasks
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
GROUP BY task_type, status;
"@
$result = sqlite3 -header -column $dbPath $sql
Write-Host $result

# 目录大小
Write-Host "`n💾 存储空间" -ForegroundColor Yellow
$dirs = @("小说章节", "图片资产", "视频资产", "剧本", "分镜", "导演规划", "资产清单", "数据库")
foreach ($dir in $dirs) {
    $path = Join-Path $projectPath $dir
    if (Test-Path $path) {
        $size = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | 
                 Measure-Object Length -Sum).Sum
        $sizeMB = [math]::Round($size / 1MB, 2)
        $fileCount = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-Host "  $dir : $sizeMB MB ($fileCount 文件)"
    }
}

Write-Host "`n✅ 状态检查完成" -ForegroundColor Green

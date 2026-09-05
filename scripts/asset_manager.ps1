#!/usr/bin/env pwsh
# 漫剧资产管理器
# 用途：管理漫剧项目的资产数据
# 用法：./asset_manager.ps1 -Project "项目名" [命令] [参数]

param(
    [Parameter(Mandatory=$true)]
    [string]$Project,               # 项目名称
    
    [Parameter(Mandatory=$false)]
    [string]$Command = "",          # 命令：list/status/add/update/generate-prompt
    
    [int]$AssetId,                  # 资产ID
    
    [string]$Type = "",             # 资产类型：character/scene/prop
    
    [string]$Name = "",             # 资产名称
    
    [string]$FilePath = ""          # 文件路径
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Join-Path $ScriptDir ".."
$ProjectsDir = Join-Path $SkillDir "projects"

# 检查项目
$projectPath = Join-Path $ProjectsDir $Project
$dbPath = Join-Path $projectPath "数据库\$Project.db"

if (-not (Test-Path $dbPath)) {
    Write-Host "错误：数据库不存在: $dbPath" -ForegroundColor Red
    Write-Host "请先运行 init_project.ps1 初始化项目" -ForegroundColor Yellow
    exit 1
}

# 检查 sqlite3
$sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
if (-not $sqlite3) {
    Write-Host "错误：未找到 sqlite3" -ForegroundColor Red
    exit 1
}

$escapedProject = $Project.Replace("'", "''")

switch ($Command) {
    "list" {
        Write-Host "`n=== 资产列表 ===`n" -ForegroundColor Cyan
        
        $sql = @"
SELECT 
    a.id,
    a.type,
    a.category,
    a.name,
    a.status,
    a.file_path,
    COUNT(sb.id) as usage_count
FROM assets a
LEFT JOIN storyboards sb ON instr(sb.asset_ids, CAST(a.id AS TEXT)) > 0
WHERE a.project_id = (SELECT id FROM projects WHERE name='$escapedProject')
GROUP BY a.id
ORDER BY a.type, a.name;
"@
        
        $result = sqlite3 -header -column $dbPath $sql
        Write-Host $result
    }
    
    "status" {
        Write-Host "`n=== 资产状态 ===`n" -ForegroundColor Cyan
        
        $sql = @"
SELECT 
    type,
    category,
    COUNT(*) as total,
    SUM(CASE WHEN status='done' THEN 1 ELSE 0 END) as completed,
    SUM(CASE WHEN status='pending' THEN 1 ELSE 0 END) as pending,
    SUM(CASE WHEN status='processing' THEN 1 ELSE 0 END) as processing
FROM assets
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
GROUP BY type, category;
"@
        
        $result = sqlite3 -header -column $dbPath $sql
        Write-Host $result
        
        Write-Host "`n=== 详细状态 ===`n" -ForegroundColor Cyan
        
        $sql2 = @"
SELECT 
    id,
    type,
    name,
    status,
    file_path
FROM assets
WHERE project_id = (SELECT id FROM projects WHERE name='$escapedProject')
ORDER BY type, name;
"@
        
        $result2 = sqlite3 -header -column $dbPath $sql2
        Write-Host $result2
    }
    
    "add" {
        if (-not $Type) { $Type = Read-Host "资产类型 (character/scene/prop)" }
        if (-not $Name) { $Name = Read-Host "资产名称" }
        if (-not $FilePath) { $FilePath = Read-Host "文件路径 (如：图片资产/人物/主角.png)" }
        
        $escapedType = $Type.Replace("'", "''")
        $escapedName = $Name.Replace("'", "''")
        $escapedPath = $FilePath.Replace("'", "''")
        
        $sql = @"
INSERT INTO assets (project_id, type, category, name, file_path, status)
VALUES ((SELECT id FROM projects WHERE name='$escapedProject'), '$escapedType', '$escapedType', '$escapedName', '$escapedPath', 'pending');
"@
        
        sqlite3 $dbPath $sql
        Write-Host "✓ 资产已添加: $Name" -ForegroundColor Green
    }
    
    "update" {
        if (-not $AssetId) {
            Write-Host "错误：请指定资产ID" -ForegroundColor Red
            exit 1
        }
        
        $newStatus = if ($args[0]) { $args[0] } else { Read-Host "新状态 (pending/processing/done/error)" }
        $newPath = if ($args[1]) { $args[1] } else { Read-Host "文件路径" }
        
        $escapedStatus = $newStatus.Replace("'", "''")
        $escapedPath = $newPath.Replace("'", "''")
        
        $sql = @"
UPDATE assets 
SET status = '$escapedStatus', file_path = '$escapedPath', updated_at = CURRENT_TIMESTAMP
WHERE id = $AssetId AND project_id = (SELECT id FROM projects WHERE name='$escapedProject');
"@
        
        sqlite3 $dbPath $sql
        Write-Host "✓ 资产状态已更新" -ForegroundColor Green
    }
    
    "generate-prompt" {
        if (-not $AssetId) {
            Write-Host "错误：请指定资产ID" -ForegroundColor Red
            exit 1
        }
        
        $sql = @"
SELECT 
    a.id,
    a.name,
    a.type,
    COALESCE(c.appearance, '') as appearance,
    COALESCE(c.clothing, '') as clothing,
    COALESCE(s.time_of_day, '') as time_of_day,
    COALESCE(s.season, '') as season,
    COALESCE(s.key_elements, '') as key_elements
FROM assets a
LEFT JOIN characters c ON a.id = c.asset_id
LEFT JOIN scenes s ON a.id = s.asset_id
WHERE a.project_id = (SELECT id FROM projects WHERE name='$escapedProject')
AND a.id = $AssetId;
"@
        
        $asset = sqlite3 -json $dbPath $sql | ConvertFrom-Json
        if ($asset) {
            Write-Host "`n=== 资产提示词生成器 ===`n" -ForegroundColor Cyan
            Write-Host "资产: $($asset[0].name) ($($asset[0].type))" -ForegroundColor Yellow
            
            switch ($asset[0].type) {
                "character" {
                    $prompt = @"
角色四视图设定图，国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，
character design sheet, character turnaround,
$($asset[0].appearance)，眼神坚定，
白皙基调，健康质感，二次元肤色，
175cm tall, 6.5 heads tall proportion, 体态英气，
墨黑长发及肩，细腻发丝清晰，
素色古装长衫，基础色，无花纹装饰，
同一画面左至右并排：人像特写+正视图+侧视图+后视图,
人像特写从头顶到锁骨完整展示，不裁切头顶，
全身立像从头顶到脚底完整展示，full body head to toe，不裁切头顶和脚部，
自然站立，月白纯色背景，均匀柔光，无硬阴影，
四视图一致性，国风二次元造型清晰，细腻线条清晰，
图中不要有任何文字
"@
                }
                "scene" {
                    $prompt = @"
国风二次元场景主视图概念图，
国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，
Japanese anime style, cel shading, fine brushstrokes,
赛璐璐平涂，细腻线条，自然光照，日式渲染，
scene design sheet, environment concept art, no people, no characters, no human figures,
室内/室外，古代民居风格，春季清晨，
前景：$($asset[0].key_elements)；中景：细节描述；后景：远景元素，
暖木色调、素雅陈设、岁月痕迹，
柔和光影，日式渲染，自然光漫射，细腻质感，
单画面构图，自然观察视角，构图能代表场景主体并展示前/中/后景层次，
画面中无任何人物，图中不要有任何文字
"@
                }
                default {
                    $prompt = "请手动填写资产提示词"
                }
            }
            
            Write-Host "`n生成提示词:" -ForegroundColor Green
            Write-Host $prompt
        }
    }
    
    default {
        Write-Host "`n=== 漫剧资产管理工具 ===`n" -ForegroundColor Cyan
        Write-Host "用法:" -ForegroundColor Yellow
        Write-Host "  ./asset_manager.ps1 -Project '项目名' -Command '命令' [参数]" -ForegroundColor White
        Write-Host ""
        Write-Host "可用命令:" -ForegroundColor Yellow
        Write-Host "  list     - 列出所有资产" -ForegroundColor White
        Write-Host "  status   - 显示资产状态统计" -ForegroundColor White
        Write-Host "  add      - 添加新资产" -ForegroundColor White
        Write-Host "  update   - 更新资产状态" -ForegroundColor White
        Write-Host "  generate-prompt - 生成资产提示词" -ForegroundColor White
        Write-Host ""
        Write-Host "示例:" -ForegroundColor Yellow
        Write-Host "  ./asset_manager.ps1 -Project '项目名' -Command list" -ForegroundColor White
        Write-Host "  ./asset_manager.ps1 -Project '项目名' -Command status" -ForegroundColor White
        Write-Host "  ./asset_manager.ps1 -Project '项目名' -Command add -Type character -Name '角色名'" -ForegroundColor White
    }
}

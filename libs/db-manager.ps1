#!/usr/bin/env pwsh
# 数据库管理器模块
# 用途：统一管理项目资产、分镜、视频等数据（替代 asset_manifest.json）
# 使用：. ./libs/db-manager.ps1

# ============================================
# 全局变量
# ============================================
$script:DbPath = $null
$script:IsConnected = $false

# ============================================
# 连接管理
# ============================================

<#
.SYNOPSIS
    连接数据库
.DESCRIPTION
    打开 SQLite 数据库连接，检查表结构
.PARAMETER DbPath
    数据库文件路径
.EXAMPLE
    Connect-Database -DbPath ".\数据库\项目.db"
#>
function Connect-Database {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DbPath
    )
    
    $script:DbPath = $DbPath
    
    if (-not (Test-Path $DbPath)) {
        Write-Host "⚠ 数据库文件不存在: $DbPath" -ForegroundColor Yellow
        return $false
    }
    
    # 测试连接
    try {
        $test = sqlite3 $DbPath "SELECT 1" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $script:IsConnected = $true
            Write-Host "✓ 已连接数据库: $DbPath" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "✗ 数据库连接失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    return $false
}

<#
.SYNOPSIS
    断开数据库连接
.EXAMPLE
    Disconnect-Database
#>
function Disconnect-Database {
    $script:DbPath = $null
    $script:IsConnected = $false
    Write-Host "✓ 已断开数据库连接" -ForegroundColor Gray
}

<#
.SYNOPSIS
    执行 SQL 查询
.DESCRIPTION
    执行 SQLite 查询并返回结果
.PARAMETER Sql
    SQL 语句
.PARAMETER Parameters
    参数数组
.EXAMPLE
    $result = Invoke-Sql -Sql "SELECT * FROM assets WHERE project_id = 1"
#>
function Invoke-Sql {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Sql,
        
        [array]$Parameters = @()
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库，请先调用 Connect-Database"
    }
    
    if ($Parameters.Count -gt 0) {
        $escapedSql = $Sql
        for ($i = 0; $i -lt $Parameters.Count; $i++) {
            $escapedSql = $escapedSql -replace "\?", "'$($Parameters[$i])'"
        }
    } else {
        $escapedSql = $Sql
    }
    
    try {
        $result = sqlite3 -json $script:DbPath $escapedSql 2>$null
        if ($result) {
            return $result | ConvertFrom-Json -ErrorAction SilentlyContinue
        }
        return @()
    } catch {
        Write-Host "✗ SQL 执行失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   SQL: $Sql" -ForegroundColor Gray
        return $null
    }
}

<#
.SYNOPSIS
    执行 SQL 命令（INSERT/UPDATE/DELETE）
.DESCRIPTION
    执行数据修改操作
.PARAMETER Sql
    SQL 语句
.EXAMPLE
    Execute-Sql -Sql "INSERT INTO assets (...) VALUES (...)"
#>
function Execute-Sql {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Sql
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库，请先调用 Connect-Database"
    }
    
    try {
        sqlite3 $script:DbPath $Sql 2>$null
        return ($LASTEXITCODE -eq 0)
    } catch {
        Write-Host "✗ SQL 执行失败: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# ============================================
# 资产管理
# ============================================

<#
.SYNOPSIS
    添加资产
.DESCRIPTION
    向数据库添加新资产记录
.PARAMETER Type
    资产类型：character/scene/prop
.PARAMETER Category
    资产分类
.PARAMETER Name
    资产名称
.PARAMETER Description
    资产描述
.PARAMETER GeneratedUrl
    生成后的 URL
.PARAMETER Prompt
    生成提示词
.PARAMETER Size
    图像尺寸：1K/2K/3K/4K
.PARAMETER Ratio
    宽高比
.EXAMPLE
    Add-Asset -Type "character" -Name "主角" -GeneratedUrl "https://..."
#>
function Add-Asset {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,
        
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [string]$Description,
        
        [string]$GeneratedUrl,
        
        [string]$Prompt,
        
        [string]$Size = "2K",
        
        [string]$Ratio = "16:9",
        
        [int]$ProjectId = 1
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    # 转义单引号
    $escapedName = $Name -replace "'", "''"
    $escapedDesc = $Description -replace "'", "''"
    $escapedUrl = $GeneratedUrl -replace "'", "''"
    $escapedPrompt = $Prompt -replace "'", "''"
    
    $sql = @"
INSERT INTO assets (
    project_id, type, category, name, description, 
    generated_url, prompt, status
) VALUES (
    $ProjectId, '$Type', '$Category', '$escapedName', '$escapedDesc',
    '$escapedUrl', '$escapedPrompt', 'done'
);
"@
    
    if (Execute-Sql -Sql $sql) {
        # 获取新生成的 ID
        $newId = Invoke-Sql -Sql "SELECT last_insert_rowid() as id"
        Write-Host "✓ 已添加资产 [ID:$($newId[0].id)] $Name ($Type)" -ForegroundColor Green
        return $newId[0].id
    }
    
    return $null
}

<#
.SYNOPSIS
    更新资产
.DESCRIPTION
    更新现有资产的信息
.PARAMETER Id
    资产 ID
.PARAMETER Status
    新状态
.PARAMETER GeneratedUrl
    新 URL
.PARAMETER Prompt
    新提示词
.EXAMPLE
    Update-Asset -Id 101 -Status "done" -GeneratedUrl "https://..."
#>
function Update-Asset {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Id,
        
        [string]$Status,
        
        [string]$GeneratedUrl,
        
        [string]$Prompt
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    $setClauses = @()
    
    if ($Status) {
        $setClauses += "status = '$Status'"
    }
    if ($GeneratedUrl) {
        $escapedUrl = $GeneratedUrl -replace "'", "''"
        $setClauses += "generated_url = '$escapedUrl'"
    }
    if ($Prompt) {
        $escapedPrompt = $Prompt -replace "'", "''"
        $setClauses += "prompt = '$escapedPrompt'"
    }
    $setClauses += "updated_at = CURRENT_TIMESTAMP"
    
    $sql = "UPDATE assets SET $($setClauses -join ', ') WHERE id = $Id"
    
    if (Execute-Sql -Sql $sql) {
        Write-Host "✓ 已更新资产 [ID:$Id]" -ForegroundColor Green
        return $true
    }
    
    return $false
}

<#
.SYNOPSIS
    删除资产
.DESCRIPTION
    从数据库删除资产记录
.PARAMETER Id
    资产 ID
.EXAMPLE
    Remove-Asset -Id 101
#>
function Remove-Asset {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Id
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    $sql = "DELETE FROM assets WHERE id = $Id"
    
    if (Execute-Sql -Sql $sql) {
        Write-Host "✓ 已删除资产 [ID:$Id]" -ForegroundColor Green
        return $true
    }
    
    return $false
}

<#
.SYNOPSIS
    获取资产列表
.DESCRIPTION
    查询资产列表，支持筛选
.PARAMETER Type
    按类型筛选
.PARAMETER Status
    按状态筛选
.PARAMETER ProjectId
    按项目筛选
.EXAMPLE
    Get-Assets -Type "character" -Status "done"
#>
function Get-Assets {
    param(
        [string]$Type,
        
        [string]$Status,
        
        [int]$ProjectId = 1
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    $whereClauses = @("project_id = $ProjectId")
    
    if ($Type) {
        $whereClauses += "type = '$Type'"
    }
    if ($Status) {
        $whereClauses += "status = '$Status'"
    }
    
    $whereSql = $whereClauses -join " AND "
    $sql = "SELECT * FROM assets WHERE $whereSql ORDER BY id"
    
    return Invoke-Sql -Sql $sql
}

<#
.SYNOPSIS
    获取单个资产
.DESCRIPTION
    根据 ID 获取资产详情
.PARAMETER Id
    资产 ID
.EXAMPLE
    Get-Asset -Id 101
#>
function Get-Asset {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Id
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    $sql = "SELECT * FROM assets WHERE id = $Id"
    $result = Invoke-Sql -Sql $sql
    
    if ($result.Count -gt 0) {
        return $result[0]
    }
    
    return $null
}

<#
.SYNOPSIS
    显示资产统计
.DESCRIPTION
    打印当前数据库中的资产统计信息
.EXAMPLE
    Show-AssetStats
#>
function Show-AssetStats {
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    Write-Host "`n📊 资产统计:" -ForegroundColor Cyan
    
    # 总数
    $total = Invoke-Sql -Sql "SELECT COUNT(*) as count FROM assets"
    Write-Host "   资产总数: $($total[0].count)" -ForegroundColor White
    
    # 按类型
    $byType = Invoke-Sql -Sql "SELECT type, COUNT(*) as count FROM assets GROUP BY type"
    Write-Host "   按类型:" -ForegroundColor Gray
    foreach ($row in $byType) {
        $typeLabel = switch ($row.type) {
            "character" { "角色" }
            "scene" { "场景" }
            "prop" { "道具" }
            default { $row.type }
        }
        Write-Host "      - $typeLabel: $($row.count)" -ForegroundColor Gray
    }
    
    # 按状态
    $byStatus = Invoke-Sql -Sql "SELECT status, COUNT(*) as count FROM assets GROUP BY status"
    Write-Host "   按状态:" -ForegroundColor Gray
    foreach ($row in $byStatus) {
        $statusLabel = switch ($row.status) {
            "done" { "已完成" }
            "pending" { "待生成" }
            "processing" { "生成中" }
            "error" { "错误" }
            default { $row.status }
        }
        $color = switch ($row.status) {
            "done" { "Green" }
            "pending" { "Yellow" }
            "error" { "Red" }
            default { "White" }
        }
        Write-Host "      - $statusLabel: $($row.count)" -ForegroundColor $color
    }
    
    Write-Host ""
}

# ============================================
# 分镜管理
# ============================================

<#
.SYNOPSIS
    添加分镜
.EXAMPLE
    Add-Storyboard -Episode 1 -Scene 1 -Sequence 1 -VisualDescription "..."
#>
function Add-Storyboard {
    param(
        [int]$ProjectId = 1,
        [int]$EpisodeNumber,
        [int]$SceneNumber,
        [int]$Sequence,
        [string]$VisualDescription,
        [string]$ShotType,
        [string]$CameraMove,
        [double]$DurationSeconds,
        [string]$Dialogue,
        [string]$SoundEffect,
        [string]$AssetIds
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    $sql = @"
INSERT INTO storyboards (
    project_id, episode_number, scene_number, sequence,
    visual_description, shot_type, camera_move, duration_seconds,
    dialogue, sound_effect, asset_ids, status
) VALUES (
    $ProjectId, $EpisodeNumber, $SceneNumber, $Sequence,
    '$($VisualDescription -replace "'", "''")', '$ShotType', '$CameraMove', $DurationSeconds,
    '$($Dialogue -replace "'", "''")', '$($SoundEffect -replace "'", "''")', '$AssetIds', 'pending'
);
"@
    
    Execute-Sql -Sql $sql
}

# ============================================
# 视频管理
# ============================================

<#
.SYNOPSIS
    添加视频片段
.EXAMPLE
    Add-VideoClip -Episode 1 -Sequence 1 -GeneratedUrl "https://..."
#>
function Add-VideoClip {
    param(
        [int]$ProjectId = 1,
        [int]$EpisodeNumber,
        [int]$Sequence,
        [string]$GeneratedUrl,
        [double]$DurationSeconds
    )
    
    if (-not $script:IsConnected) {
        throw "未连接数据库"
    }
    
    $sql = @"
INSERT INTO video_clips (
    project_id, episode_number, sequence, generated_url, duration_seconds, status
) VALUES (
    $ProjectId, $EpisodeNumber, $Sequence, '$GeneratedUrl', $DurationSeconds, 'done'
);
"@
    
    Execute-Sql -Sql $sql
}

# ============================================
# 导出功能
# ============================================

<#
.SYNOPSIS
    导出资产为 CSV
.EXAMPLE
    Export-Assets -Path ".\assets.csv"
#>
function Export-Assets {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [int]$ProjectId = 1
    )
    
    $assets = Get-Assets -ProjectId $ProjectId
    
    $csvData = $assets | ForEach-Object {
        [PSCustomObject]@{
            ID = $_.id
            Type = $_.type
            Category = $_.category
            Name = $_.name
            Status = $_.status
            Size = $_.size
            Ratio = $_.ratio
            URL = $_.generated_url
            CreatedAt = $_.created_at
        }
    }
    
    $csvData | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
    Write-Host "✓ 已导出到: $Path" -ForegroundColor Green
}

# ============================================
# 导出函数
# ============================================
Export-ModuleMember -Function Connect-Database, Disconnect-Database, Invoke-Sql, Execute-Sql
Export-ModuleMember -Function Add-Asset, Update-Asset, Remove-Asset, Get-Assets, Get-Asset, Show-AssetStats
Export-ModuleMember -Function Add-Storyboard, Add-VideoClip
Export-ModuleMember -Function Export-Assets

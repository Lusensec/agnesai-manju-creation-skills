#!/usr/bin/env pwsh
# 资产索引管理器模块
# 用途：管理 asset_manifest.json，提供增删改查功能
# 使用：. ./libs/manifest-manager.ps1

# ============================================
# 全局变量
# ============================================
$script:ManifestPath = $null
$script:ManifestData = $null

# ============================================
# 核心函数
# ============================================

<#
.SYNOPSIS
    加载资产索引文件
.DESCRIPTION
    读取并解析 asset_manifest.json，如果不存在则创建新文件
.PARAMETER Path
    索引文件路径
.EXAMPLE
    Load-Manifest -Path ".\asset_manifest.json"
#>
function Load-Manifest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    $script:ManifestPath = $Path
    
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw -Encoding UTF8
        $script:ManifestData = $content | ConvertFrom-Json
        Write-Host "✓ 已加载索引文件: $Path" -ForegroundColor Green
    } else {
        # 创建新索引
        $script:ManifestData = @{
            version = "1.0"
            project = ""
            assets = @()
            storyboards = @()
            videos = @()
            created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        $script:ManifestPath = $Path
        Write-Host "✓ 已创建新索引文件: $Path" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    保存资产索引
.DESCRIPTION
    将当前索引数据写回 JSON 文件
.EXAMPLE
    Save-Manifest
#>
function Save-Manifest {
    param()
    
    if (-not $script:ManifestPath) {
        throw "未加载索引文件，请先调用 Load-Manifest"
    }
    
    $script:ManifestData.last_updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $json = $script:ManifestData | ConvertTo-Json -Depth 10
    $json | Out-File -FilePath $script:ManifestPath -Encoding UTF8
    
    Write-Host "✓ 已保存索引文件" -ForegroundColor Green
}

<#
.SYNOPSIS
    添加资产到索引
.DESCRIPTION
    添加新的资产记录到索引
.PARAMETER Type
    资产类型：character/scene/prop
.PARAMETER Category
    资产分类：人物/场景/物品
.PARAMETER Name
    资产名称
.PARAMETER Url
    生成后的 URL
.PARAMETER Size
    图像尺寸：1K/2K/3K/4K
.PARAMETER Ratio
    宽高比
.PARAMETER Status
    状态：pending/processing/done/error
.PARAMETER Prompt
    生成提示词
.PARAMETER Metadata
    扩展元数据
.EXAMPLE
    Add-Asset -Type "character" -Name "主角" -Url "https://..." -Size "2K" -Ratio "16:9"
#>
function Add-Asset {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [string]$Category,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [string]$Url,
        
        [string]$Size = "2K",
        
        [string]$Ratio = "16:9",
        
        [string]$Status = "pending",
        
        [string]$Prompt,
        
        [hashtable]$Metadata = @{}
    )
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    # 生成唯一 ID
    $maxId = 0
    if ($script:ManifestData.assets.Count -gt 0) {
        $maxId = ($script:ManifestData.assets | Measure-Object -Property id -Maximum).Maximum
    }
    $newId = $maxId + 1
    
    $asset = @{
        id = $newId
        type = $Type
        category = $Category
        name = $Name
        url = $Url
        size = $Size
        ratio = $Ratio
        status = $Status
        prompt = $Prompt
        metadata = $Metadata
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        updated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:ManifestData.assets += ,$asset
    
    Write-Host "✓ 已添加资产 [ID:$newId] $Name ($Type)" -ForegroundColor Green
    return $newId
}

<#
.SYNOPSIS
    更新资产状态
.DESCRIPTION
    更新现有资产的状态和 URL
.PARAMETER Id
    资产 ID
.PARAMETER Status
    新状态
.PARAMETER Url
    新 URL
.PARAMETER Prompt
    新提示词
.EXAMPLE
    Update-Asset -Id 101 -Status "done" -Url "https://..."
#>
function Update-Asset {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Id,
        
        [string]$Status,
        
        [string]$Url,
        
        [string]$Prompt
    )
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    $asset = $script:ManifestData.assets | Where-Object { $_.id -eq $Id }
    
    if (-not $asset) {
        throw "未找到 ID 为 $Id 的资产"
    }
    
    if ($Status) { $asset.status = $Status }
    if ($Url) { $asset.url = $Url }
    if ($Prompt) { $asset.prompt = $Prompt }
    $asset.updated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host "✓ 已更新资产 [ID:$Id]" -ForegroundColor Green
}

<#
.SYNOPSIS
    删除资产
.DESCRIPTION
    从索引中删除资产记录
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
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    $assetIndex = -1
    for ($i = 0; $i -lt $script:ManifestData.assets.Count; $i++) {
        if ($script:ManifestData.assets[$i].id -eq $Id) {
            $assetIndex = $i
            break
        }
    }
    
    if ($assetIndex -eq -1) {
        throw "未找到 ID 为 $Id 的资产"
    }
    
    $script:ManifestData.assets = $script:ManifestData.assets[0..($assetIndex-1)] + $script:ManifestData.assets[($assetIndex+1)..($script:ManifestData.assets.Count-1)]
    
    Write-Host "✓ 已删除资产 [ID:$Id]" -ForegroundColor Green
}

<#
.SYNOPSIS
    获取资产列表
.DESCRIPTION
    按条件筛选资产
.PARAMETER Type
    资产类型过滤
.PARAMETER Status
    状态过滤
.EXAMPLE
    Get-Assets -Type "character" -Status "done"
#>
function Get-Assets {
    param(
        [string]$Type,
        
        [string]$Status
    )
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    $assets = $script:ManifestData.assets
    
    if ($Type) {
        $assets = $assets | Where-Object { $_.type -eq $Type }
    }
    
    if ($Status) {
        $assets = $assets | Where-Object { $_.status -eq $Status }
    }
    
    return $assets
}

<#
.SYNOPSIS
    添加分镜记录
.DESCRIPTION
    在索引中记录分镜信息
.PARAMETER Episode
    集数
.PARAMETER Scene
    场次
.PARAMETER Shots
    镜头数组
.EXAMPLE
    Add-Storyboard -Episode 1 -Scene 1 -Shots @(@{id=1; duration=3; ...})
#>
function Add-Storyboard {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Episode,
        
        [Parameter(Mandatory=$true)]
        [int]$Scene,
        
        [Parameter(Mandatory=$true)]
        [array]$Shots
    )
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    $storyboard = @{
        episode = $Episode
        scene = $Scene
        shots = $Shots
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:ManifestData.storyboards += ,$storyboard
    
    Write-Host "✓ 已添加分镜 EP${Episode} SC${Scene}" -ForegroundColor Green
}

<#
.SYNOPSIS
    添加视频记录
.DESCRIPTION
    在索引中记录视频生成结果
.PARAMETER Episode
    集数
.PARAMETER Sequence
    镜头序号
.PARAMETER Url
    视频 URL
.PARAMETER Duration
    时长（秒）
.EXAMPLE
    Add-Video -Episode 1 -Sequence 1 -Url "https://..." -Duration 5
#>
function Add-Video {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Episode,
        
        [Parameter(Mandatory=$true)]
        [int]$Sequence,
        
        [Parameter(Mandatory=$true)]
        [string]$Url,
        
        [double]$Duration
    )
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    $video = @{
        episode = $Episode
        sequence = $Sequence
        url = $Url
        duration = $Duration
        status = "done"
        created_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $script:ManifestData.videos += ,$video
    
    Write-Host "✓ 已添加视频 EP${Episode} SEQ${Sequence}" -ForegroundColor Green
}

<#
.SYNOPSIS
    显示索引统计
.DESCRIPTION
    打印当前索引的统计信息
.EXAMPLE
    Show-ManifestStats
#>
function Show-ManifestStats {
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    Write-Host "`n📊 索引统计:" -ForegroundColor Cyan
    
    # 资产统计
    $assets = $script:ManifestData.assets
    Write-Host "   资产总数: $($assets.Count)" -ForegroundColor White
    
    $charAssets = ($assets | Where-Object { $_.type -eq 'character' }).Count
    $sceneAssets = ($assets | Where-Object { $_.type -eq 'scene' }).Count
    $propAssets = ($assets | Where-Object { $_.type -eq 'prop' }).Count
    Write-Host "   - 角色: $charAssets" -ForegroundColor Gray
    Write-Host "   - 场景: $sceneAssets" -ForegroundColor Gray
    Write-Host "   - 道具: $propAssets" -ForegroundColor Gray
    
    $doneAssets = ($assets | Where-Object { $_.status -eq 'done' }).Count
    $pendingAssets = ($assets | Where-Object { $_.status -eq 'pending' }).Count
    Write-Host "   - 已完成: $doneAssets" -ForegroundColor Green
    Write-Host "   - 待生成: $pendingAssets" -ForegroundColor Yellow
    
    # 分镜统计
    $storyboards = $script:ManifestData.storyboards
    Write-Host "   分镜总数: $($storyboards.Count)" -ForegroundColor White
    
    # 视频统计
    $videos = $script:ManifestData.videos
    Write-Host "   视频总数: $($videos.Count)" -ForegroundColor White
    
    Write-Host ""
}

<#
.SYNOPSIS
    导出索引为 CSV
.DESCRIPTION
    将资产索引导出为 CSV 文件，便于查看和编辑
.PARAMETER Path
    输出文件路径
.EXAMPLE
    Export-Manifest -Path ".\assets.csv"
#>
function Export-Manifest {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    if (-not $script:ManifestData) {
        throw "未加载索引文件"
    }
    
    $assets = $script:ManifestData.assets | ForEach-Object {
        [PSCustomObject]@{
            ID = $_.id
            Type = $_.type
            Category = $_.category
            Name = $_.name
            Status = $_.status
            Size = $_.size
            Ratio = $_.ratio
            URL = $_.url
            CreatedAt = $_.created_at
        }
    }
    
    $assets | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
    Write-Host "✓ 已导出到: $Path" -ForegroundColor Green
}

# ============================================
# 导出函数
# ============================================
Export-ModuleMember -Function Load-Manifest, Save-Manifest, Add-Asset, Update-Asset, Remove-Asset, Get-Assets, Add-Storyboard, Add-Video, Show-ManifestStats, Export-Manifest

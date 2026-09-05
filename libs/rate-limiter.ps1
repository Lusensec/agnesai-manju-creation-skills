#!/usr/bin/env pwsh
# 速率限制器模块
# 用途：管理 Agnes AI API 调用速率，避免被封禁
# 使用：. ./libs/rate-limiter.ps1

# ============================================
# 全局配置
# ============================================
$script:RateLimits = @{
    # 对话模型：20次/分钟
    chat = @{
        MaxRequests = 20
        WindowSeconds = 60
        LastRequests = @()
    }
    
    # 图像模型：10次/分钟（2K）
    image = @{
        MaxRequests = 10
        WindowSeconds = 60
        LastRequests = @()
    }
    
    # 视频模型：1次/分钟
    video = @{
        MaxRequests = 1
        WindowSeconds = 60
        LastRequests = @()
    }
}

# ============================================
# 核心函数
# ============================================

<#
.SYNOPSIS
    等待并满足速率限制
.DESCRIPTION
    检查指定类型的 API 调用是否超过速率限制，如果超限则等待
.PARAMETER Type
    API 类型：chat/image/video
.PARAMETER Force
    强制跳过检查（仅用于测试）
.EXAMPLE
    Wait-RateLimit -Type image
#>
function Wait-RateLimit {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('chat', 'image', 'video')]
        [string]$Type,
        
        [switch]$Force
    )
    
    if ($Force) { return }
    
    $config = $script:RateLimits[$Type]
    $now = Get-Date
    
    # 清理窗口外的记录
    $cutoff = $now.AddSeconds(-$config.WindowSeconds)
    $config.LastRequests = $config.LastRequests | Where-Object { $_ -gt $cutoff }
    
    # 检查是否超限
    if ($config.LastRequests.Count -ge $config.MaxRequests) {
        $oldestRequest = $config.LastRequests[0]
        $waitSeconds = $config.WindowSeconds - ($now - $oldestRequest).TotalSeconds
        
        if ($waitSeconds -gt 0) {
            Write-Host "⏳ 速率限制：$Type 模型已用 $($config.LastRequests.Count)/$($config.MaxRequests) 次/分钟" -ForegroundColor Yellow
            Write-Host "   等待 $([math]::Ceiling($waitSeconds)) 秒..." -ForegroundColor Gray
            Start-Sleep -Seconds [math]::Ceiling($waitSeconds)
            
            # 重新清理
            $now = Get-Date
            $cutoff = $now.AddSeconds(-$config.WindowSeconds)
            $config.LastRequests = $config.LastRequests | Where-Object { $_ -gt $cutoff }
        }
    }
    
    # 记录本次请求
    $config.LastRequests += $now
    $script:RateLimits[$Type] = $config
}

<#
.SYNOPSIS
    获取当前速率状态
.DESCRIPTION
    显示各类型 API 的当前使用情况和剩余配额
.EXAMPLE
    Get-RateLimitStatus
#>
function Get-RateLimitStatus {
    Write-Host "`n📊 速率限制状态:" -ForegroundColor Cyan
    Write-Host "   类型      已用/上限      剩余      下次可用" -ForegroundColor Gray
    
    $now = Get-Date
    $cutoff = $now.AddSeconds(-60)
    
    foreach ($type in @('chat', 'image', 'video')) {
        $config = $script:RateLimits[$type]
        $activeRequests = ($config.LastRequests | Where-Object { $_ -gt $cutoff }).Count
        $remaining = [math]::Max(0, $config.MaxRequests - $activeRequests)
        
        # 计算下次可用时间
        if ($activeRequests -ge $config.MaxRequests -and $config.LastRequests.Count -gt 0) {
            $oldest = ($config.LastRequests | Where-Object { $_ -gt $cutoff } | Sort-Object)[0]
            $nextAvailable = $oldest.AddSeconds($config.WindowSeconds)
            $waitTime = ($nextAvailable - $now).TotalSeconds
            $nextStr = "等待 $([math]::Ceiling($waitTime))s"
        } else {
            $nextStr = "随时可用"
        }
        
        $status = switch ($type) {
            'chat' { '对话模型' }
            'image' { '图像模型' }
            'video' { '视频模型' }
        }
        
        Write-Host "   $status    $activeRequests/$($config.MaxRequests)       $remaining       $nextStr" -ForegroundColor White
    }
    Write-Host ""
}

<#
.SYNOPSIS
    重置速率计数器
.DESCRIPTION
    清除所有请求记录（用于测试或手动重置）
.EXAMPLE
    Reset-RateLimit
#>
function Reset-RateLimit {
    param(
        [ValidateSet('chat', 'image', 'video', 'all')]
        [string]$Type = 'all'
    )
    
    if ($Type -eq 'all') {
        $script:RateLimits.chat.LastRequests = @()
        $script:RateLimits.image.LastRequests = @()
        $script:RateLimits.video.LastRequests = @()
        Write-Host "✓ 已重置所有速率计数器" -ForegroundColor Green
    } else {
        $script:RateLimits[$Type].LastRequests = @()
        Write-Host "✓ 已重置 $Type 速率计数器" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    带速率限制的调用函数
.DESCRIPTION
    自动等待速率限制后执行 API 调用
.PARAMETER Type
    API 类型
.PARAMETER ScriptBlock
    要执行的代码块
.PARAMETER MaxRetries
    最大重试次数
.EXAMPLE
    Invoke-RateLimited -Type image -MaxRetries 3 -ScriptBlock {
        Invoke-RestMethod -Uri $url -Method Post -Body $body
    }
#>
function Invoke-RateLimited {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Type,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [int]$MaxRetries = 3
    )
    
    $attempts = 0
    $lastError = $null
    
    do {
        try {
            # 等待速率限制
            Wait-RateLimit -Type $Type
            
            # 执行调用
            $result = & $ScriptBlock
            return $result
        }
        catch {
            $attempts++
            $lastError = $_
            
            # 检查是否是速率限制错误
            if ($_.Exception.Response.StatusCode.value__ -eq 429) {
                Write-Host "⚠ API 速率限制 (429)，等待 60 秒后重试..." -ForegroundColor Yellow
                Start-Sleep -Seconds 60
                continue
            }
            
            # 检查是否是超时
            if ($_.Exception.Message -match 'timeout|timeout') {
                Write-Host "⚠ 请求超时，等待 30 秒后重试..." -ForegroundColor Yellow
                Start-Sleep -Seconds 30
                continue
            }
        }
    } while ($attempts -lt $MaxRetries)
    
    # 所有重试失败
    Write-Host "✗ 达到最大重试次数 ($MaxRetries)" -ForegroundColor Red
    throw $lastError
}

# ============================================
# 导出函数
# ============================================
Export-ModuleMember -Function Wait-RateLimit, Get-RateLimitStatus, Reset-RateLimit, Invoke-RateLimited

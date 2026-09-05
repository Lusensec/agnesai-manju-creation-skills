#!/usr/bin/env pwsh
# API 客户端模块
# 用途：封装 Agnes AI API 调用，提供重试和错误处理
# 使用：. ./libs/api-client.ps1

# ============================================
# 配置
# ============================================
$script:ApiConfig = @{
    BaseUrl = "https://api.agnes-ai.cn/v1"
    ChatModel = "agnes-2.5-flash"
    ImageModel = "agnes-image-2.5-flash"
    VideoModel = "agnes-video-2.5-flash"
    TimeoutSeconds = 300
}

# ============================================
# 辅助函数
# ============================================

<#
.SYNOPSIS
    从 .env 文件读取 API Key
.DESCRIPTION
    自动查找并读取 API Key，支持相对路径和绝对路径
#>
function Get-APIKey {
    $scriptPaths = @(
        ".env",
        "./.env",
        "$PSScriptRoot/../.env",
        "$env:AGNES_API_KEY"
    )
    
    foreach ($path in $scriptPaths) {
        if ($path -and (Test-Path $path)) {
            $content = Get-Content $path -Raw
            if ($content -match 'AGNES_API_KEY=(sk-[^\s]+)') {
                return $Matches[1]
            }
        }
    }
    
    return $null
}

<#
.SYNOPSIS
    构建标准请求头
#>
function New-RequestHeaders {
    param(
        [string]$ApiKey
    )
    
    if (-not $ApiKey) {
        $ApiKey = Get-APIKey
    }
    
    if (-not $ApiKey) {
        throw "未找到 API Key，请配置 .env 文件或设置 AGNES_API_KEY 环境变量"
    }
    
    return @{
        "Authorization" = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }
}

# ============================================
# 对话模型调用
# ============================================

<#
.SYNOPSIS
    调用对话模型
.DESCRIPTION
    发送消息到 Agnes 2.5 Flash 对话模型，支持流式输出
.PARAMETER Messages
    消息数组，格式：@(@{role="user"; content="你好"})
.PARAMETER Temperature
    温度参数 (0-2)
.PARAMETER MaxTokens
    最大输出 token 数
.PARAMETER Stream
    是否流式输出
.EXAMPLE
    $result = Invoke-ChatAPI -Messages @(@{role="user"; content="编写剧本"})
#>
function Invoke-ChatAPI {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Messages,
        
        [double]$Temperature = 0.7,
        
        [int]$MaxTokens = 4000,
        
        [switch]$Stream,
        
        [string]$Model = $script:ApiConfig.ChatModel
    )
    
    # 导入速率限制器
    . "$PSScriptRoot\rate-limiter.ps1"
    
    $body = @{
        model = $Model
        messages = $Messages
        temperature = $Temperature
        max_tokens = $MaxTokens
    }
    
    if ($Stream) {
        $body.stream = $true
    }
    
    $headers = New-RequestHeaders
    
    $result = Invoke-RateLimited -Type chat -MaxRetries 3 -ScriptBlock {
        $response = Invoke-RestMethod `
            -Uri "$($script:ApiConfig.BaseUrl)/chat/completions" `
            -Method Post `
            -Headers $headers `
            -Body ($body | ConvertTo-Json -Depth 10) `
            -TimeoutSec $script:ApiConfig.TimeoutSeconds
        
        return $response
    }
    
    return $result
}

<#
.SYNOPSIS
    简化版对话调用
.DESCRIPTION
    单消息简化调用，适合简单问答
.PARAMETER Prompt
    用户提示词
.PARAMETER SystemPrompt
    系统提示词（可选）
.EXAMPLE
    $text = Simple-Chat -Prompt "编写一个穿越题材的剧本"
#>
function Simple-Chat {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$SystemPrompt = "你是一个专业的漫剧编剧助手。"
    )
    
    $messages = @()
    if ($SystemPrompt) {
        $messages += @{role = "system"; content = $SystemPrompt}
    }
    $messages += @{role = "user"; content = $Prompt}
    
    $result = Invoke-ChatAPI -Messages $messages
    return $result.choices[0].message.content
}

# ============================================
# 图像模型调用
# ============================================

<#
.SYNOPSIS
    调用图像生成模型
.DESCRIPTION
    生成图像，支持文生图和图生图
.PARAMETER Prompt
    图像描述提示词
.PARAMETER Size
    输出尺寸：1K/2K/3K/4K
.PARAMETER Ratio
    宽高比：1:1/16:9/9:16 等
.PARAMETER Images
    参考图像 URL 数组（图生图）
.PARAMETER ResponseFormat
    响应格式：url 或 b64_json
.EXAMPLE
    $result = Invoke-ImageAPI -Prompt "国风角色设定图" -Size "2K" -Ratio "16:9"
#>
function Invoke-ImageAPI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Size = "2K",
        
        [string]$Ratio = "16:9",
        
        [array]$Images,
        
        [string]$ResponseFormat = "url",
        
        [string]$Model = $script:ApiConfig.ImageModel
    )
    
    # 导入速率限制器
    . "$PSScriptRoot\rate-limiter.ps1"
    
    $body = @{
        model = $Model
        prompt = $Prompt
        size = $Size
        ratio = $Ratio
        extra_body = @{
            response_format = $ResponseFormat
        }
    }
    
    if ($Images -and $Images.Count -gt 0) {
        $body.extra_body.image = $Images
    }
    
    $headers = New-RequestHeaders
    
    $result = Invoke-RateLimited -Type image -MaxRetries 3 -ScriptBlock {
        $response = Invoke-RestMethod `
            -Uri "$($script:ApiConfig.BaseUrl)/images/generations" `
            -Method Post `
            -Headers $headers `
            -Body ($body | ConvertTo-Json -Depth 10) `
            -TimeoutSec $script:ApiConfig.TimeoutSeconds
        
        return $response
    }
    
    return $result
}

<#
.SYNOPSIS
    多图合成调用
.DESCRIPTION
    使用多张参考图合成新图像
.PARAMETER Prompt
    目标描述
.PARAMETER ReferenceImages
    参考图像 URL 数组（最多 5 张）
.PARAMETER Size
    输出尺寸
.PARAMETER Ratio
    宽高比
.EXAMPLE
    $result = Invoke-MultiImageAPI -Prompt "角色走向窗边" -ReferenceImages @("url1", "url2")
#>
function Invoke-MultiImageAPI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [Parameter(Mandatory=$true)]
        [array]$ReferenceImages,
        
        [string]$Size = "2K",
        
        [string]$Ratio = "16:9"
    )
    
    if ($ReferenceImages.Count -gt 5) {
        Write-Host "⚠ 最多支持 5 张参考图，已自动截取前 5 张" -ForegroundColor Yellow
        $ReferenceImages = $ReferenceImages[0..4]
    }
    
    return Invoke-ImageAPI `
        -Prompt $Prompt `
        -Size $Size `
        -Ratio $Ratio `
        -Images $ReferenceImages
}

# ============================================
# 视频模型调用
# ============================================

<#
.SYNOPSIS
    调用视频生成模型
.DESCRIPTION
    生成视频，支持文生视频和图片参考
.PARAMETER Prompt
    视频描述提示词
.PARAMETER Image
    参考图像 URL
.PARAMETER Audio
    参考音频 URL
.PARAMETER Keyframes
    首尾帧图像 URL 数组
.EXAMPLE
    $result = Invoke-VideoAPI -Prompt "角色走向窗边" -Image "https://..."
#>
function Invoke-VideoAPI {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Image,
        
        [string]$Audio,
        
        [array]$Keyframes
    )
    
    # 导入速率限制器
    . "$PSScriptRoot\rate-limiter.ps1"
    
    $body = @{
        model = $script:ApiConfig.VideoModel
        prompt = $Prompt
    }
    
    $extraBody = @{}
    
    if ($Image) {
        $extraBody.reference_images = @($Image)
    }
    
    if ($Audio) {
        $extraBody.audio_references = @($Audio)
    }
    
    if ($Keyframes -and $Keyframes.Count -gt 0) {
        $extraBody.keyframes = $Keyframes
    }
    
    if ($extraBody.Count -gt 0) {
        $body.extra_body = $extraBody
    }
    
    $headers = New-RequestHeaders
    
    # 视频模型严格串行，每次间隔 60 秒
    $result = Invoke-RateLimited -Type video -MaxRetries 3 -ScriptBlock {
        $response = Invoke-RestMethod `
            -Uri "$($script:ApiConfig.BaseUrl)/videos" `
            -Method Post `
            -Headers $headers `
            -Body ($body | ConvertTo-Json -Depth 10) `
            -TimeoutSec ($script:ApiConfig.TimeoutSeconds * 3)  # 视频生成需要更长时间
        
        return $response
    }
    
    return $result
}

<#
.SYNOPSIS
    查询视频生成状态
.DESCRIPTION
    查询异步视频生成任务的状态
.PARAMETER VideoId
    视频任务 ID
.EXAMPLE
    $status = Query-VideoStatus -VideoId "vid_123"
#>
function Query-VideoStatus {
    param(
        [Parameter(Mandatory=$true)]
        [string]$VideoId
    )
    
    $headers = New-RequestHeaders
    
    $response = Invoke-RestMethod `
        -Uri "$($script:ApiConfig.BaseUrl)/videos/$VideoId" `
        -Method Get `
        -Headers $headers `
        -TimeoutSec 30
    
    return $response
}

# ============================================
# 导出函数
# ============================================
Export-ModuleMember -Function Get-APIKey, Invoke-ChatAPI, Simple-Chat, Invoke-ImageAPI, Invoke-MultiImageAPI, Invoke-VideoAPI, Query-VideoStatus

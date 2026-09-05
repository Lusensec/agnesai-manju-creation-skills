#!/usr/bin/env pwsh
# 漫剧创作工作流主脚本
# 用途：按照步骤引导用户完成漫剧创作全流程
# 用法：./workflow.ps1 -Project "项目名"

param(
    [Parameter(Mandatory=$true)]
    [string]$Project,
    
    [switch]$SkipCheck,
    [switch]$Resume
)

# ============================================
# 初始化
# ============================================
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillDir = Join-Path $ScriptDir ".."
$ProjectsDir = Join-Path $SkillDir "projects"
$ProjectDir = Join-Path $ProjectsDir $Project
$LedsDir = Join-Path $ScriptDir "../libs"
$TemplatesDir = Join-Path $ScriptDir "../templates"

# 加载模块
Write-Host "📦 加载模块..." -ForegroundColor Cyan
. "$LedsDir\rate-limiter.ps1"
. "$LedsDir\api-client.ps1"
. "$LedsDir\manifest-manager.ps1"

Write-Host ""

# ============================================
# 检查项目是否存在
# ============================================
if (-not (Test-Path $ProjectDir)) {
    Write-Host "✗ 错误：项目 '$Project' 不存在" -ForegroundColor Red
    Write-Host "  请先运行 init_project.ps1 创建项目" -ForegroundColor Yellow
    exit 1
}

# 加载项目配置
$configPath = Join-Path $ProjectDir "project_config.json"
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
    Write-Host "✓ 已加载项目配置: $($config.name)" -ForegroundColor Green
} else {
    Write-Host "⚠ 未找到项目配置文件" -ForegroundColor Yellow
}

# 加载资产索引
$manifestPath = Join-Path $ProjectDir "资产清单\asset_manifest.json"
Load-Manifest -Path $manifestPath

Write-Host ""

# ============================================
# 前置检查（第一步）
# ============================================
if (-not $SkipCheck) {
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         第一步：前置检查                             ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # 检查 API Key
    $apiKey = Get-APIKey
    if (-not $apiKey) {
        Write-Host "⚠ 未检测到 API Key" -ForegroundColor Yellow
        Write-Host "  请编辑 .env 文件并填入 Agnes AI API Key" -ForegroundColor Gray
        Write-Host "  路径: $SkillDir\.env" -ForegroundColor Gray
        $continue = Read-Host "`n是否继续？(y/n)"
        if ($continue -ne 'y') {
            Write-Host "已取消" -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host "✓ API Key 已配置" -ForegroundColor Green
    }
    
    # 检查 sqlite3
    $sqlite3 = Get-Command sqlite3 -ErrorAction SilentlyContinue
    if (-not $sqlite3) {
        Write-Host "⚠ 未检测到 sqlite3" -ForegroundColor Yellow
        Write-Host "  数据库功能将受限，但创作仍可继续" -ForegroundColor Gray
    } else {
        Write-Host "✓ sqlite3 已安装: $($sqlite3.Source)" -ForegroundColor Green
    }
    
    # 检查小说章节
    $novelDir = Join-Path $ProjectDir "小说章节"
    if (Test-Path $novelDir) {
        $novelFiles = Get-ChildItem $novelDir -Filter "*.md"
        if ($novelFiles.Count -gt 0) {
            Write-Host "✓ 找到 $($novelFiles.Count) 个小说章节文件" -ForegroundColor Green
            $novelFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
        } else {
            Write-Host "⚠ 小说章节目录为空" -ForegroundColor Yellow
            Write-Host "  请手动添加小说章节文件或运行 init_project.ps1" -ForegroundColor Gray
        }
    } else {
        Write-Host "⚠ 未找到小说章节目录" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "✓ 前置检查完成" -ForegroundColor Green
    Write-Host ""
}

# ============================================
# 第二步：剧本创作
# ============================================
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         第二步：剧本创作                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查小说文件
$novelDir = Join-Path $ProjectDir "小说章节"
$novelFiles = Get-ChildItem $novelDir -Filter "*.md" -ErrorAction SilentlyContinue

if ($novelFiles.Count -eq 0) {
    Write-Host "⚠ 未找到小说章节文件" -ForegroundColor Yellow
    $inputPath = Read-Host "请输入小说文件路径（或按 Enter 跳过）"
    if ($inputPath) {
        if (Test-Path $inputPath) {
            Copy-Item $inputPath $novelDir -Force
            Write-Host "✓ 已复制小说文件" -ForegroundColor Green
            $novelFiles = Get-ChildItem $novelDir -Filter "*.md"
        } else {
            Write-Host "✗ 文件不存在" -ForegroundColor Red
        }
    }
}

if ($novelFiles.Count -gt 0) {
    Write-Host "`n📖 检测到以下小说章节:" -ForegroundColor Cyan
    $novelFiles | ForEach-Object { Write-Host "   - $($_.Name)" -ForegroundColor Gray }
    Write-Host ""
    
    # 读取第一章内容
    $firstChapter = $novelFiles | Sort-Object Name | Select-Object -First 1
    $novelContent = Get-Content $firstChapter.FullName -Raw -Encoding UTF8
    
    Write-Host "📝 正在生成剧本..." -ForegroundColor Cyan
    Write-Host "   （这需要一些时间，请耐心等待）" -ForegroundColor Gray
    Write-Host ""
    
    # 构建提示词
    $scriptPrompt = @"
请根据以下小说第一章内容，编写漫剧剧本。

小说内容：
$novelContent

要求：
1. 改编为 1-3 集短剧，每集约 1 分钟
2. 使用 XML 格式输出剧本
3. 包含场景描述、台词、情绪标注
4. 保留核心情节和人物性格
5. 压缩比控制在 40% 以内

请按以下格式输出：
<script>
<episode number="1" title="标题" duration="60">
  <synopsis>剧情梗概</synopsis>
  <scene>
    <description>场景描述</description>
    <dialogue character="角色名">台词内容</dialogue>
  </scene>
</episode>
</script>
"@
    
    try {
        # 调用 API 生成剧本
        $scriptContent = Simple-Chat -Prompt $scriptPrompt -SystemPrompt "你是一个专业的漫剧编剧，擅长将小说改编为短剧剧本。"
        
        # 保存剧本
        $scriptDir = Join-Path $ProjectDir "剧本"
        $scriptFile = Join-Path $scriptDir "EP01_剧本.xml"
        $scriptContent | Out-File -FilePath $scriptFile -Encoding UTF8
        
        Write-Host ""
        Write-Host "✓ 剧本已生成并保存" -ForegroundColor Green
        Write-Host "  文件: $scriptFile" -ForegroundColor Gray
        Write-Host ""
        
        # 展示剧本
        Write-Host "📄 剧本内容预览:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        $previewLines = $scriptContent -split "`n" | Select-Object -First 30
        $previewLines | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        if (($scriptContent -split "`n").Count -gt 30) {
            Write-Host "   ... (共 $(( $scriptContent -split "`n" ).Count) 行)" -ForegroundColor Gray
        }
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host ""
        
        # 用户确认
        $confirm = Read-Host "是否确认剧本？(y=确认/n=修改/q=退出)"
        if ($confirm -eq 'n') {
            Write-Host ""
            Write-Host "请输入修改意见（或直接输入新剧本内容）:" -ForegroundColor Yellow
            $userInput = Read-Host
            if ($userInput) {
                $scriptContent = $userInput
                $scriptContent | Out-File -FilePath $scriptFile -Encoding UTF8
                Write-Host "✓ 剧本已更新" -ForegroundColor Green
            }
        } elseif ($confirm -eq 'q') {
            Write-Host "已取消" -ForegroundColor Yellow
            exit 0
        }
        
        # 保存到数据库
        if (Get-Command sqlite3 -ErrorAction SilentlyContinue) {
            $dbPath = Join-Path $ProjectDir "数据库\$Project.db"
            $escapedContent = $scriptContent -replace "'", "''"
            sqlite3 $dbPath "INSERT OR REPLACE INTO scripts (project_id, episode_number, title, content) VALUES ((SELECT id FROM projects WHERE name='$Project'), 1, 'EP01', '$escapedContent');"
            Write-Host "✓ 剧本已保存到数据库" -ForegroundColor Green
        }
        
    } catch {
        Write-Host "✗ 剧本生成失败: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  请检查 API Key 是否正确配置" -ForegroundColor Gray
        exit 1
    }
} else {
    Write-Host "⚠ 跳过剧本生成（无小说文件）" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 第三步：资产生成
# ============================================
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         第三步：资产生成                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 显示速率限制状态
Get-RateLimitStatus

# 资产生成提示词模板
$assetPrompts = @{
    character = @{
        name = "角色名"
        prompt = "角色四视图设定图，国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，character design sheet, character turnaround，[外貌描述]，同一画面左至右并排：人像特写+正视图+侧视图+后视图，月白纯色背景，均匀柔光，无硬阴影，图中不要有任何文字"
    }
    scene = @{
        name = "场景名"
        prompt = "国风二次元场景主视图概念图，国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，Japanese anime style, cel shading, fine brushstrokes，scene design sheet, environment concept art, no people, no characters，[场景描述]，柔和光影，日式渲染，自然光漫射，图中不要有任何文字"
    }
    prop = @{
        name = "道具名"
        prompt = "国风二次元道具特写图，国风二次元，新国潮美学，日式动画渲染，赛璐璐平涂，细腻笔触，prop closeup, detailed object shot, no people，[道具描述]，月白纯色背景，均匀柔光，图中不要有任何文字"
    }
}

# 交互式添加资产
Write-Host "🎨 资产生成" -ForegroundColor Yellow
Write-Host ""

$addMore = $true
while ($addMore) {
    $assetType = Read-Host "资产类型 (character/scene/prop，或按 Enter 跳过)"
    if (-not $assetType) { break }
    
    $assetName = Read-Host "资产名称"
    if (-not $assetName) { continue }
    
    $assetPrompt = Read-Host "提示词（按 Enter 使用默认）"
    if (-not $assetPrompt) {
        $assetPrompt = $assetPrompts[$assetType].prompt -replace "\[.*?\]", $assetName
    }
    
    Write-Host "`n⏳ 正在生成资产 [$assetName]..." -ForegroundColor Cyan
    
    try {
        $result = Invoke-ImageAPI -Prompt $assetPrompt -Size "2K" -Ratio "16:9"
        
        if ($result.data -and $result.data[0].url) {
            $assetUrl = $result.data[0].url
            
            # 添加到索引
            $assetId = Add-Asset -Type $assetType -Category $assetType -Name $assetName -Url $assetUrl -Size "2K" -Ratio "16:9" -Status "done" -Prompt $assetPrompt
            Save-Manifest
            
            Write-Host "✓ 资产已生成并保存 [ID:$assetId]" -ForegroundColor Green
            Write-Host "  URL: $assetUrl" -ForegroundColor Gray
        } else {
            Write-Host "⚠ 生成失败，请检查响应" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ 资产生成失败: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    $continue = Read-Host "是否继续添加资产？(y/n)"
    if ($continue -ne 'y') { $addMore = $false }
}

Write-Host ""

# ============================================
# 第四步：导演分镜
# ============================================
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         第四步：导演分镜                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 读取剧本
$scriptDir = Join-Path $ProjectDir "剧本"
$scriptFiles = Get-ChildItem $scriptDir -Filter "*.xml"
if ($scriptFiles.Count -gt 0) {
    $scriptContent = Get-Content $scriptFiles[0].FullName -Raw -Encoding UTF8
    
    Write-Host "📝 正在生成导演规划和分镜表..." -ForegroundColor Cyan
    Write-Host ""
    
    $storyboardPrompt = @"
请根据以下剧本生成导演规划和分镜表。

剧本内容：
$scriptContent

要求：
1. 生成导演规划（分场、情绪、过渡）
2. 生成详细分镜表（镜头设计、景别运镜、台词音效）
3. 每个片段 ≤15 秒
4. 标注引用的资产 ID

请按以下格式输出：
## 导演规划
[分场汇总表]
[逐场注意事项]
[场间过渡设计]

## 分镜表
### 第1场
| 序号 | 画面描述 | 时长 | 景别 | 运镜 | 台词 | 音效 | 引用资产 |
|------|----------|------|------|------|------|------|----------|
| 1 | ... | 3s | 特写 | 固定 | ... | ... | 101,201 |
...
"@
    
    try {
        $storyboardContent = Simple-Chat -Prompt $storyboardPrompt -SystemPrompt "你是一位经验丰富的漫剧导演，擅长分镜设计和节奏把控。"
        
        # 保存导演规划
        $directorDir = Join-Path $ProjectDir "导演规划"
        $directorFile = Join-Path $directorDir "EP01_导演规划.md"
        $storyboardContent | Out-File -FilePath $directorFile -Encoding UTF8
        
        # 保存分镜表
        $storyboardOutDir = Join-Path $ProjectDir "分镜"
        $storyboardFile = Join-Path $storyboardOutDir "EP01_分镜表.md"
        $storyboardContent | Out-File -FilePath $storyboardFile -Encoding UTF8
        
        Write-Host "✓ 导演规划和分镜表已生成" -ForegroundColor Green
        Write-Host "  文件: $directorFile" -ForegroundColor Gray
        Write-Host "  文件: $storyboardFile" -ForegroundColor Gray
        Write-Host ""
        
        # 展示预览
        Write-Host "📋 内容预览:" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Gray
        $previewLines = $storyboardContent -split "`n" | Select-Object -First 20
        $previewLines | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
        Write-Host "----------------------------------------" -ForegroundColor Gray
        Write-Host ""
        
        # 用户确认
        $confirm = Read-Host "是否确认分镜内容？(y=确认/n=修改/q=退出)"
        if ($confirm -eq 'n') {
            Write-Host ""
            $userInput = Read-Host "请输入修改后的内容："
            if ($userInput) {
                $userInput | Out-File -FilePath $directorFile -Encoding UTF8
                $userInput | Out-File -FilePath $storyboardFile -Encoding UTF8
                Write-Host "✓ 内容已更新" -ForegroundColor Green
            }
        } elseif ($confirm -eq 'q') {
            Write-Host "已取消" -ForegroundColor Yellow
            exit 0
        }
        
    } catch {
        Write-Host "✗ 分镜生成失败: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠ 跳过导演分镜（未找到剧本文件）" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 第五步：分镜图创作
# ============================================
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         第五步：分镜图创作                           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 获取资产列表
$assets = Get-Assets
if ($assets.Count -gt 0) {
    Write-Host "🎨 当前资产列表:" -ForegroundColor Yellow
    $assets | ForEach-Object { Write-Host "   [ID:$($_.id)] $($_.name) ($($_.type)) - $($_.url)" -ForegroundColor White }
    Write-Host ""
    
    $generateStoryboard = Read-Host "是否生成分镜图？(y/n)"
    if ($generateStoryboard -eq 'y') {
        # 简化：基于资产生成示例分镜图
        Write-Host "⏳ 正在生成分镜图（可能需要几分钟）..." -ForegroundColor Cyan
        Write-Host ""
        
        $count = 0
        foreach ($asset in $assets) {
            if ($asset.type -eq 'character' -and $asset.url) {
                Write-Host "   生成角色分镜图 [$($asset.name)]..." -ForegroundColor Gray
                
                try {
                    $result = Invoke-MultiImageAPI `
                        -Prompt "$($asset.name) 在场景中行走的动画帧" `
                        -ReferenceImages @($asset.url) `
                        -Size "2K" `
                        -Ratio "16:9"
                    
                    if ($result.data -and $result.data[0].url) {
                        $imageUrl = $result.data[0].url
                        Add-Asset -Type "storyboard" -Category "分镜" -Name "$($asset.name)_分镜" -Url $imageUrl -Size "2K" -Ratio "16:9" -Status "done"
                        Save-Manifest
                        Write-Host "   ✓ 已保存" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "   ⚠ 生成失败: $($_.Exception.Message)" -ForegroundColor Yellow
                }
                
                $count++
                if ($count -ge 5) { break }  # 限制数量避免超时
            }
        }
        
        Write-Host ""
        Write-Host "✓ 分镜图生成完成" -ForegroundColor Green
        Show-ManifestStats
    }
} else {
    Write-Host "⚠ 跳过分镜图生成（暂无资产）" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 第六步：视频创作
# ============================================
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         第六步：视频创作                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 获取分镜图资产
$storyboardAssets = Get-Assets -Type "storyboard"
if ($storyboardAssets.Count -gt 0) {
    Write-Host "🎬 当前分镜图资产:" -ForegroundColor Yellow
    $storyboardAssets | ForEach-Object { Write-Host "   [ID:$($_.id)] $($_.name) - $($_.url)" -ForegroundColor White }
    Write-Host ""
    
    # 选择屏幕方向
    $screenType = Read-Host "选择视频方向 (h=横屏/v=竖屏，默认横屏)"
    $ratio = if ($screenType -eq 'v') { "9:16" } else { "16:9" }
    Write-Host "✓ 使用 $ratio 比例" -ForegroundColor Green
    Write-Host ""
    
    $generateVideo = Read-Host "是否开始视频生成？(y/n)"
    if ($generateVideo -eq 'y') {
        Write-Host "⏳ 正在生成视频（每个视频约需 1 分钟，请耐心等待）..." -ForegroundColor Cyan
        Write-Host ""
        
        $count = 0
        foreach ($sb in $storyboardAssets) {
            if ($sb.url) {
                Write-Host "   生成视频 [$($sb.name)]..." -ForegroundColor Gray
                
                try {
                    $videoResult = Invoke-VideoAPI `
                        -Prompt "$($sb.name) 的动态视频" `
                        -Image $sb.url
                    
                    if ($videoResult.data -and $videoResult.data[0].url) {
                        $videoUrl = $videoResult.data[0].url
                        Add-Video -Episode 1 -Sequence ($count + 1) -Url $videoUrl -Duration 5
                        Save-Manifest
                        Write-Host "   ✓ 已保存" -ForegroundColor Green
                    }
                } catch {
                    Write-Host "   ⚠ 生成失败: $($_.Exception.Message)" -ForegroundColor Yellow
                }
                
                # 严格间隔 60 秒（视频模型限制）
                if ($count -lt $storyboardAssets.Count - 1) {
                    Write-Host "   ⏳ 等待 60 秒..." -ForegroundColor Yellow
                    Start-Sleep -Seconds 60
                }
                
                $count++
                if ($count -ge 3) { break }  # 限制数量避免超时
            }
        }
        
        Write-Host ""
        Write-Host "✓ 视频生成完成" -ForegroundColor Green
        Show-ManifestStats
    }
} else {
    Write-Host "⚠ 跳过视频生成（暂无分镜图资产）" -ForegroundColor Yellow
}

Write-Host ""

# ============================================
# 完成
# ============================================
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                    创作完成！                       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Show-ManifestStats

Write-Host "📁 项目文件位置: $ProjectDir" -ForegroundColor Cyan
Write-Host "📊 索引文件位置: $manifestPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ 恭喜！你的漫剧创作已完成！" -ForegroundColor Green
Write-Host ""

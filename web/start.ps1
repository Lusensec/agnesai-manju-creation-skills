#!/usr/bin/env pwsh
# 漫剧创作 Web GUI 启动脚本
# 用途：一键启动 Web 服务并打开浏览器

param(
    [int]$Port = 3000,
    [switch]$NoOpen
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WebDir = Join-Path $ScriptDir "web"

Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         漫剧创作 Web GUI 启动器                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 检查 Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "✗ 未检测到 Node.js，请先安装 Node.js" -ForegroundColor Red
    Write-Host "  下载地址：https://nodejs.org/" -ForegroundColor Gray
    exit 1
}

Write-Host "✓ Node.js 版本: $(node --version)" -ForegroundColor Green

# 检查依赖
$packageJson = Join-Path $WebDir "package.json"
$nodeModules = Join-Path $WebDir "node_modules"

if (-not (Test-Path $nodeModules)) {
    Write-Host "`n📦 正在安装依赖..." -ForegroundColor Cyan
    Set-Location $WebDir
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "✗ 依赖安装失败" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ 依赖安装完成" -ForegroundColor Green
}

# 启动服务器
Write-Host "`n🚀 启动 Web 服务器..." -ForegroundColor Cyan
Set-Location $WebDir

# 设置端口
$env:PORT = $Port

# 启动并等待
$process = Start-Process -FilePath "node" -ArgumentList "server.js" -PassThru -WindowStyle Normal

Write-Host "✓ 服务器已启动 (PID: $($process.Id))" -ForegroundColor Green
Write-Host "  访问地址: http://localhost:$Port" -ForegroundColor Cyan
Write-Host ""

# 打开浏览器
if (-not $NoOpen) {
    Write-Host "🌐 正在打开浏览器..." -ForegroundColor Gray
    Start-Process "http://localhost:$Port"
}

Write-Host ""
Write-Host "💡 提示：" -ForegroundColor Yellow
Write-Host "  - 按 Ctrl+C 停止服务器" -ForegroundColor Gray
Write-Host "  - 或通过任务管理器结束进程" -ForegroundColor Gray
Write-Host ""

# 等待用户关闭
Write-Host "按任意键停止服务器..." -ForegroundColor Gray
$null = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# 终止进程
Stop-Process -Id $process.Id -Force
Write-Host "`n✓ 服务器已停止" -ForegroundColor Green

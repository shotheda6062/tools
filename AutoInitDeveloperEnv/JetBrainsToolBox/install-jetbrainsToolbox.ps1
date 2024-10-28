Import-Module .\JetBrainsVersionCheck.psm1
Import-Module .\DownloadModule.psm1

function Install-Toolbox {
    param(
        [string]$InstallerPath
    )
    
    try {
        # 設定環境變數
        $env:START_JETBRAINS_TOOLBOX_AFTER_INSTALL = if ($LaunchAfterInstall) { "1" } else { "0" }

        # 檢查安裝檔
        if (!(Test-Path $InstallerPath)) {
            throw "Installer not found at: $InstallerPath"
        }

        Write-Host "Installing JetBrains Toolbox..." -ForegroundColor Cyan
        Write-Host "Installation file: $InstallerPath" -ForegroundColor Gray
        
        # 關閉現有進程
        Get-Process | Where-Object { $_.ProcessName -eq "jetbrains-toolbox" } | ForEach-Object {
            Write-Host "Stopping existing Toolbox process..." -ForegroundColor Yellow
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }

        # 執行安裝
        Write-Host "Starting installation..." -ForegroundColor Cyan
        Start-Process -FilePath $InstallerPath -ArgumentList "/silent" -Wait
        
        # 驗證安裝
        $toolboxPath = "$env:LOCALAPPDATA\JetBrains\Toolbox\bin\jetbrains-toolbox.exe"
        
        if (Test-Path $toolboxPath) {
            Write-Host "Installation completed successfully!" -ForegroundColor Green
        } else {
            throw "Installation failed - Toolbox not found at expected location"
        }
    }
    catch {
        Write-Host "Installation error: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

Clear-Host

$latestInfo = Get-DownloadInfo -Application 'ToolBox'
$version = $latestInfo.Version
$installerPath = Join-Path $env:TEMP "jetbrains-toolbox-$version.exe"


Write-Host "Starting Jetbrains ToolBox Installation..." -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor DarkGray
Write-Host "Installation Details:"
Write-Host "  Version: $version"
Write-Host "  Installer Path: $installerPath"
Write-Host "  Install Path: $env:LOCALAPPDATA\JetBrains\Toolbox\bin\jetbrains-toolbox.exe"
Write-Host "----------------------------------------" -ForegroundColor DarkGray

$downloadResult = Download-File -Url $latestInfo.DownloadUrl -OutputPath $installerPath


    if ($downloadResult) {
        # 安裝
        Install-Toolbox -InstallerPath $installerPath
        
        Write-Host "`nInstallation Complete!" -ForegroundColor Green
        Write-Host "Version: $($latestInfo.Version)" -ForegroundColor Cyan
        Write-Host "To start JetBrains Toolbox, run:" -ForegroundColor Yellow
        Write-Host "  & '$env:LOCALAPPDATA\JetBrains\Toolbox\toolbox.exe'" -ForegroundColor Gray
    }
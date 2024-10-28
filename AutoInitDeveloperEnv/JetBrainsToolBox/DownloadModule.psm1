# DownloadModule.psm1

<#
.SYNOPSIS
    Downloads a file from a URL with progress bar and retry mechanism.

.DESCRIPTION
    A PowerShell module that provides robust file downloading capabilities with:
    - Visual progress bar showing download progress
    - Download speed calculation
    - Estimated time remaining
    - Automatic retry on failure
    - TLS 1.2 support
    - Optimized connection settings

.EXAMPLE
    Download-File -Url "https://example.com/file.zip" -OutputPath "C:\Downloads\file.zip"
    Downloads a file showing progress and handles any errors

.PARAMETER Url
    The URL of the file to download

.PARAMETER OutputPath
    The local path where the file should be saved

.PARAMETER MaxRetries
    Maximum number of retry attempts if download fails (default: 3)

.OUTPUTS
    [bool] Returns $true if download successful, throws an exception if all retries fail
#>
function Download-File {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Url,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$MaxRetries = 3
    )
    
    $attempt = 0
    do {
        $attempt++
        try {
            # Initialize HttpClient with improved performance settings
            Add-Type -AssemblyName System.Net.Http
            $client = New-Object System.Net.Http.HttpClient
            $client.Timeout = [System.TimeSpan]::FromMinutes(30)
            $client.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0")
            
            # Configure TLS and connection settings
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
            [System.Net.ServicePointManager]::DefaultConnectionLimit = 100
            
            # Get file size and initialize download stream
            $response = $client.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
            $totalBytes = $response.Content.Headers.ContentLength
            $responseStream = $response.Content.ReadAsStreamAsync().Result
            
            # Initialize console output
            Write-Host "Starting download..."
            Write-Host ""  # Reserve line for progress bar
            $originalTop = [Console]::CursorTop - 1
            
            # Initialize file stream and buffer
            $fileStream = [System.IO.File]::Create($OutputPath)
            $totalBytesRead = 0
            $buffer = New-Object byte[] 1MB
            $startTime = Get-Date
            $lastBytes = 0
            $lastTime = $startTime
            
            # Main download loop
            do {
                $bytesRead = $responseStream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -gt 0) {
                    # Write downloaded bytes to file
                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalBytesRead += $bytesRead
                    
                    # Calculate progress statistics
                    $percentComplete = [Math]::Floor(($totalBytesRead / $totalBytes) * 100)
                    $downloadedMB = [Math]::Round($totalBytesRead / 1MB, 2)
                    $totalMB = [Math]::Round($totalBytes / 1MB, 2)
                    
                    # Update download speed calculation (every second)
                    $currentTime = Get-Date
                    $timeSpan = ($currentTime - $lastTime).TotalSeconds
                    if ($timeSpan -ge 1) {
                        # Calculate current speed
                        $bytesPerSecond = ($totalBytesRead - $lastBytes) / $timeSpan
                        $speedMBps = [Math]::Round($bytesPerSecond / 1MB, 2)
                        $lastBytes = $totalBytesRead
                        $lastTime = $currentTime
                        
                        # Calculate ETA
                        if ($bytesPerSecond -gt 0) {
                            $remainingBytes = $totalBytes - $totalBytesRead
                            $remainingSeconds = $remainingBytes / $bytesPerSecond
                            $remainingTime = [TimeSpan]::FromSeconds($remainingSeconds)
                            $remainingStr = "{0:hh\:mm\:ss}" -f $remainingTime
                            
                            # Update progress bar display
                            [Console]::SetCursorPosition(0, $originalTop)
                            [Console]::Write("`r" + " ".PadRight([Console]::WindowWidth))
                            [Console]::SetCursorPosition(0, $originalTop)
                            
                            # Create progress bar
                            $barWidth = 50
                            $completed = [Math]::Floor($barWidth * ($percentComplete / 100))
                            $remaining = $barWidth - $completed
                            
                            # Construct progress message
                            $progressBar = "[Download] "
                            $progressBar += "".PadLeft($completed, [char]9608)  # █
                            $progressBar += "".PadLeft($remaining, [char]9617)  # ░
                            $progressBar += " $percentComplete% "
                            $progressBar += "Downloading: $downloadedMB MB / $totalMB MB"
                            $progressBar += " ($speedMBps MB/s, ETA: $remainingStr)"
                            
                            Write-Host $progressBar
                        }
                    }
                }
            } while ($bytesRead -gt 0)
            
            # Display completion status
            [Console]::SetCursorPosition(0, $originalTop)
            [Console]::Write("`r" + " ".PadRight([Console]::WindowWidth))
            [Console]::SetCursorPosition(0, $originalTop)
            
            # Calculate and display final statistics
            $completedBar = "[Download] " + "".PadLeft(50, [char]9608)
            $totalTime = [Math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
            $averageSpeed = [Math]::Round($totalBytes / 1MB / $totalTime, 2)
            Write-Host "$completedBar 100% Download completed: $totalMB MB (Average: $averageSpeed MB/s)" -ForegroundColor Green
            Write-Host "`nDownload completed successfully" -ForegroundColor Green

            return $true
        }
        catch {
            Write-Host "`nDownload attempt $attempt failed: $($_.Exception.Message)" -ForegroundColor Yellow
            if ($attempt -lt $MaxRetries) {
                Write-Host "Retrying download in 5 seconds..." -ForegroundColor Gray
                Start-Sleep -Seconds 5
            }
        }
        finally {
            # Clean up resources
            if ($responseStream) { $responseStream.Dispose() }
            if ($fileStream) { $fileStream.Dispose() }
            if ($client) { $client.Dispose() }
        }
    } while ($attempt -lt $MaxRetries)
    
    throw "Download failed after $MaxRetries attempts"
}

# Export the function
Export-ModuleMember -Function Download-File
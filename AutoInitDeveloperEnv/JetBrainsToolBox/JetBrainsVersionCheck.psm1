<# 
.SYNOPSIS
    Gets the latest version information for JetBrains products.

.DESCRIPTION
    Retrieves the latest version information and download URL for specified JetBrains products
    including ToolBox, IntelliJ IDEA Ultimate (IIU), and IntelliJ IDEA Community Edition (IIC).

.PARAMETER Application
    The JetBrains application to check. Valid values are:
    - ToolBox
    - IIU (IntelliJ IDEA Ultimate)
    - IIC (IntelliJ IDEA Community)

.EXAMPLE
    Get-DownloadInfo -Application 'ToolBox'
    Returns version information for JetBrains ToolBox

.EXAMPLE
    Get-DownloadInfo -Application 'IIU'
    Returns version information for IntelliJ IDEA Ultimate

.OUTPUTS
    Returns a hashtable containing:
    - Version: The latest version number
    - DownloadUrl: Direct download URL for the application
#>

function Get-DownloadInfo {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('ToolBox', 'IIC', 'IIU')]
        [string]$Application
    )

    # Define constants
    $IDE_TYPES = @('IIC', 'IIU')
    
    # Determine API URL based on application type
    $apiUrl = switch ($Application) {
        'ToolBox' { 
            'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' 
        }
        { $IDE_TYPES -contains $_ } { 
            'https://data.services.jetbrains.com/products/releases?code=IIC,IIU&latest=true&type=release' 
        }
    }

    try {
        Write-Host "Fetching latest version information..." -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing

        # Parse response based on application type
        $result = switch ($Application) {
            'ToolBox' {
                @{
                    Version = $response.TBA[0].version
                    DownloadUrl = $response.TBA[0].downloads.windows.link
                }
            }
            { $IDE_TYPES -contains $_ } {
                @{
                    Version = $response.$Application[0].version
                    DownloadUrl = $response.$Application[0].downloads.windows.link
                }
            }
        }

        # Output results
        Write-Host "Latest version: $($result.Version)" -ForegroundColor Green
        Write-Host "Download URL: $($result.DownloadUrl)" -ForegroundColor Gray
        
        return $result
    }
    catch {
        throw "Failed to fetch latest version: $($_.Exception.Message)"
    }
}


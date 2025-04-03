#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   .\scripts\Uninstall.ps1                                                      ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function UnInstall-OpenVpnIntercept {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    try {
        # Ensure script runs as admin
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
                     [Security.Principal.WindowsBuiltinRole]::Administrator)) {
            Write-Error "This script must be run as administrator."
            exit 1
        }

        # Registry path and value
        $regPath = "HKLM:\SOFTWARE\F-Secure\FSVpnSDK"
        $regValue = "AppPath"

        try {
            $fSecurePath = (Get-ItemProperty -Path $regPath -Name $regValue).$regValue
        } catch {
            Write-Error "Failed to read F-Secure path from registry."
            exit 1
        }

        # Paths
        $backupPath = "C:\Temp\FSecure-Backup\openvpn.exe"
        $originalExePath = Join-Path $fSecurePath "openvpn.exe"

        # Validate backup exists
        if (-not (Test-Path $backupPath)) {
            Write-Error "Backup file not found at $backupPath"
            exit 1
        }

        # Stop the process if running
        $proc = Get-Process | Where-Object { $_.Path -eq $originalExePath } -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Output "Stopping openvpn.exe process..."
            $proc | Stop-Process -Force
        }

        # Restore the original file
        try {
            Copy-Item -Path $backupPath -Destination $originalExePath -Force
            Write-Output "Restored backup to $originalExePath"
        } catch {
            Write-Error "Failed to restore backup: $_"
            exit 1
        }

    } catch {
        $ErrorOccured = $True
        Show-ExceptionDetails $_ -ShowStack
    }
}


#This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host " Launching in Admin mode" -f DarkRed
    Start-Process pwsh.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    exit
}

UnInstall-OpenVpnIntercept

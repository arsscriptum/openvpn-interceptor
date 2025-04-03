#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   .\scripts\Install.ps1                                                        ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Stop-ProcessByExePath {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Full path to the target executable.")]
        [string]$ExePath
    )

    if (-not (Test-Path $ExePath)) {
        Write-Error "File not found: $ExePath"
        return
    }

    # Normalize the input path
    $normalizedPath = (Get-Item -LiteralPath $ExePath).FullName.ToLower()

    # Get processes with matching executable path
    $matchingProcs = Get-CimInstance Win32_Process |
        Where-Object {
            $_.ExecutablePath -and
            ($_.ExecutablePath.ToLower() -eq $normalizedPath)
        }

    if ($matchingProcs.Count -eq 0) {
        Write-Host "No processes found running: $ExePath"
        return
    }

    foreach ($proc in $matchingProcs) {
        Write-Host "Stopping process ID $($proc.ProcessId) ($($proc.Name))"
        Stop-Process -Id $proc.ProcessId -Force
    }
}

function IsVPNConnected {
    [CmdletBinding()]
    param ()

    $regPath = "HKLM:\SOFTWARE\F-Secure\FSVpnSDK"
    $valueName = "CurrentVpnState"

    try {
        $state = (Get-ItemProperty -Path $regPath -Name $valueName).$valueName
    } catch {
        Write-Warning "Unable to read registry value '$valueName' from '$regPath'"
        return $false
    }

    switch ($state.ToLower()) {
        "off"         { return $false }
        "connecting"  { return $true }
        "connected"   { return $true }
        default       { return $false }
    }
}


function New-FSecureOpenVPN {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$OpenVpnPath
    )


    try {
        # Check for admin privileges
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error "This script must be run as Administrator."
            exit 1
        }

        $IsConnected = IsVPNConnected
        if($IsConnected){
            Write-Error "Please disconnect your Fsecure VPN"
            Start-Sleep 2
            exit 1
        }

        # Get F-Secure AppPath from registry
        $regPath = "HKLM:\SOFTWARE\F-Secure\FSVpnSDK"
        try {
            $FsecurePath = (Get-ItemProperty -Path $regPath -Name "AppPath").AppPath
        } catch {
            Write-Error "Failed to read AppPath from registry at $regPath."
            Start-Sleep 2
            exit 1
        }

        # Verify F-Secure openvpn.exe exists
        $originalExe = Join-Path $FsecurePath "openvpn.exe"
        if (-not (Test-Path $originalExe)) {
            Write-Error "F-Secure openvpn.exe not found at: $originalExe"
            Start-Sleep 2
            exit 1
        }

        # Backup original executable
        $backupPath = "C:\Temp\FSecure-Backup"
        $backupExe = Join-Path $backupPath "openvpn.exe"
        if (-not (Test-Path $backupExe)) {
          New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
          Copy-Item -Path $originalExe -Destination $backupExe -Force
          Write-Host "Backup created at $backupExe"    
        }else{
            Write-Host "Backup already exists!"    
            for($i = 1 ; $i -lt 100 ; $i++){ 
                $fn = "openvpn_" + ($i) + ".exe"
                $backupExe = Join-Path $backupPath $fn
                if(!(Test-Path "$backupExe")){
                    break;
                }
            }
            if (-not (Test-Path $backupExe)) {
              Copy-Item -Path $originalExe -Destination $backupExe -Force
              Write-Host "Backup created at $backupExe"   
          }

        }

        # Replace with your custom version
        if (-not (Test-Path $OpenVpnPath)) {
            Write-Error "Your custom openvpn.exe not found at: $OpenVpnPath"
            Start-Sleep 2
            exit 1
        }

        Write-Host "Check if the exe is running"

        Stop-ProcessByExePath $originalExe

        Copy-Item -Path $OpenVpnPath -Destination $originalExe -Force
        Write-Host "Replaced F-Secure openvpn.exe with custom version." -f DarkGreen
        Start-Sleep 2

    } catch {
        $ErrorOccured = $True
        Show-ExceptionDetails $_ -ShowStack
    }
}


#This will self elevate the script so with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host " Launching in Admin mode" -f DarkRed
    Start-Process pwsh.exe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

$RootPath = (Resolve-Path -Path "$PSScriptRoot\..").Path
$BinPath = (Resolve-Path -Path "$RootPath\bin").Path
[string[]]$ExePaths = Get-ChildItem -Path $BinPath -file -Filter "openvpn-intercept.exe" -Recurse | Select -ExpandProperty FullName
if($($ExePaths.Count) -eq 0){
    Write-Error "no exe found"
}
$Exe = $ExePaths[0]


New-FSecureOpenVPN $Exe

#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   .\scripts\ModKey.ps1                                                         ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝




function PrependStringToBinaryFile {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "String to prepend")]
        [string]$String,

        [Parameter(Mandatory = $true, HelpMessage = "Path to the binary file")]
        [string]$FilePath
    )

    try {
        if (-not (Test-Path $FilePath)) {
            throw "The specified file does not exist: $FilePath"
        }

        $tempFile = "$FilePath.tmp"

        # Convert string to bytes
        $stringBytes = [System.Text.Encoding]::ASCII.GetBytes($String)

        # Read original binary content
        $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

        # Write new file with prepended string
        [System.IO.File]::WriteAllBytes($tempFile, $stringBytes + $fileBytes)

        # Replace original file
        Move-Item -Force -Path $tempFile -Destination $FilePath

        Write-Host "Successfully prepended string to $FilePath"
    }
    catch {
        Write-Error "Failed to prepend string to file: $_"
    }
}

function FixClientKey {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    try {

        $Path = "C:\ProgramData\F-Secure\FSVpnSDK\keys\client.key"
        $backupFile = "$Path" + ".backup"
        if (-not (Test-Path $backupFile)) {
            throw "The specified file does not exist: $Path"
        }

        Move-Item $backupFile $Path -Force

    }
    catch {
        Write-Error "Failed to prepend string to file: $_"
    }
}


function BreakClientKey {
    [CmdletBinding(SupportsShouldProcess)]
    param ()

    try {

        $Path = "C:\ProgramData\F-Secure\FSVpnSDK\keys\client.key"
        if (-not (Test-Path $Path)) {
            throw "The specified file does not exist: $Path"
        }

        $backupFile = "$Path" + ".backup"
        if (-not (Test-Path $backupFile)) {
            Write-Host "Making client.key backup to $backupFile"
            Copy-Item $Path $backupFile
        }

        PrependStringToBinaryFile -String "Test" -FilePath $Path 

    }
    catch {
        Write-Error "Failed to prepend string to file: $_"
    }
}

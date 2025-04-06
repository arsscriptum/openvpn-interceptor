
#┌────────────────────────────────────────────────────────────────────────────────┐
#│                                                                                │
#│   .\scripts\Fix-RsaPrivateKeyPem.ps1                                           │
#│                                                                                │
#├────────────────────────────────────────────────────────────────────────────────┤
#│   Guillaume Plante <codegp@icloud.com>                                         │
#│   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      │
#└────────────────────────────────────────────────────────────────────────────────┘


function Format-RsaPrivateKeyBlock {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true,Position=0)]
        [string]$PrivateKeyBlock
    )

    try {
        if (-not (Test-Path $InputPath)) {
            throw "Input file not found: $InputPath"
        }
        $beginHeader = "-----BEGIN RSA PRIVATE KEY-----"
        $endHeader = "-----END RSA PRIVATE KEY-----"
        $beginKey = "<key>"
        $endKey = "</key>"

        [string]$allrawlines = Get-Content -Path $InputPath -Raw
        [string]$allrawlines = $allrawlines.Replace("`r", '').Replace("`n", '')


        $allrawlines = $allrawlines -replace "`r", '' -replace "`n+", "`n" # Normalize to Unix-style

        # Extract header
        if (!$allrawlines.Contains('-----BEGIN RSA PRIVATE KEY-----')) {
            throw "Missing BEGIN header"
        }
        if (!$allrawlines.Contains('Proc-Type: 4,ENCRYPTED')) {
            throw "Missing Proc-Type header"
        }
        $IndexProc = $allrawlines.IndexOf('Proc-Type: 4,ENCRYPTED')
        if (!$allrawlines.Contains('DEK-Info:')) {
            throw "Missing DEK-Info header"
        }
        $IndexDek = $allrawlines.IndexOf('DEK-Info: ')
        $IndexBeginHeader = $allrawlines.IndexOf($beginHeader)
        $IndexEndHeader = $allrawlines.IndexOf($endHeader)
        $IndexBeginKey = $allrawlines.IndexOf($beginKey)
        $IndexEndKey = $allrawlines.IndexOf($endKey)
        $IndexDekEnd = $allrawlines.IndexOf(',', $IndexDek) + 17

        $allrawlines = $allrawlines.Insert($IndexBeginKey, "`n")
        $allrawlines = $allrawlines.Insert($IndexBeginHeader + 1, "`n")
        $allrawlines = $allrawlines.Insert($IndexProc + 2, "`n")
        $allrawlines = $allrawlines.Insert($IndexDek + 3, "`n")
        $allrawlines = $allrawlines.Insert($IndexDekEnd + 4, "`n")
        $allrawlines = $allrawlines.Insert($IndexEndKey + 5, "`n")
        $allrawlines = $allrawlines.Insert($IndexEndHeader + 6, "`n")

        $allrawlines = ($allrawlines -split '(.{1,64})' | Where-Object { [string]::IsNullOrEmpty($_) -eq $False }) -join "`n"
        [string[]]$lines = $allrawlines.split("`n") | Where-Object { [string]::IsNullOrEmpty($_) -eq $False }

        $dekLine = ($lines -split "`n" | Where-Object { $_ -match '^DEK-Info: ' })
        $dekLineIndex = $lines.IndexOf($dekLine)
        
        $i = 0
        $added = $false
        foreach ($l in $lines) {
            if (($i -eq $dekLineIndex) -and ($added -eq $False)) {
                $added = $true
                Write-Output "$l`n"
            }else{
                Write-Output "$l"
            }
            $i++
        }

    }
    catch {
        Write-Error "❌ Error: $_"
    }
}


function Repair-RsaPrivateKeyFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Path to original RSA private key (unenforced format)")]
        [string]$InputPath,
        [Parameter(Mandatory = $false)]
        [switch]$Save
    )
    try {
        if (-not (Test-Path $InputPath)) {
            throw "Input file not found: $InputPath"
        }
    
        [string]$allrawlines = Get-Content -Path $InputPath -Raw
        $outputLines = Format-RsaPrivateKeyBlock $allrawlines
        
        if($Save){
            $OutputPath = (Get-Item $InputPath).Basename + ".pem"
            [string]$OutputPath = Join-Path $((Get-Item $InputPath).DirectoryName) $((Get-Item $InputPath).Basename + "_formated.pem")
            $outputLines | Set-Content -Path "$OutputPath" -Force
            Write-Host "✅ PEM format fixed and saved to: $OutputPath" -f DarkRed
        }
        $outputLines
    }
    catch {
        Write-Error "❌ Error: $_"
    }
}

function Convert-ToDateTime {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$InputString
    )

    $formats = @(
        'MMM d HH:mm:ss yyyy GMT',
        'MMM dd HH:mm:ss yyyy GMT'
    )
    $culture = [System.Globalization.CultureInfo]::InvariantCulture

    foreach ($f in $formats) {
        try {
            return [datetime]::ParseExact($InputString, $f, $culture)
        } catch {
            continue
        }
    }

    Write-Warning "Failed to parse date: $InputString"
    return $null
}


function Test-CertificateParsedObject {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [pscustomobject]$Cert,
        [Parameter(Mandatory = $false)]
        [switch]$CheckExpiration,
        [Parameter(Mandatory = $false)]
        [string]$CertificateErrors = $Null
    )

    process {
        [bool]$IsValid = $True



        $SetErrorVariable = $False -eq [string]::IsNullOrEmpty($CertificateErrors)

        $format = 'MMM d HH:mm:ss yyyy GMT'
        $culture = [System.Globalization.CultureInfo]::InvariantCulture
        $localErrors = @()

        if (-not $Cert.Subject) { $localErrors += "Subject is missing."; $IsValid = $False }
        if (-not $Cert.Issuer) { $localErrors += "Issuer is missing."; $IsValid = $False }
        if (-not $Cert.Thumbprint) { $localErrors += "Thumbprint is missing." }

        if (-not $Cert.ValidTo -or -not $Cert.ValidFrom) {
            $localErrors += "Validity dates are incomplete."
            $IsValid = $False
        }
        elseif ($CheckExpiration) {
            $now = Get-Date
            $ValidToDate = Convert-ToDateTime $Cert.ValidTo
            $ValidFromDate = Convert-ToDateTime $Cert.ValidFrom
            if ($now -lt $ValidToDate) { $localErrors += "Certificate is not yet valid."; $IsValid = $False }
            if ($now -gt $ValidFromDate) { $localErrors += "Certificate has expired."; $IsValid = $False }

        }

        $validAlgos = @('RSA', 'ECDSA', 'DSA', 'Ed25519', 'Ed448', 'rsaEncryption')
        if ($Cert.PublicKeyAlgorithm -and $validAlgos -notcontains $Cert.PublicKeyAlgorithm) {
            $localErrors += "Unrecognized public key algorithm: $($Cert.PublicKeyAlgorithm)"
            $IsValid = $False
        }

        $numErrors = $localErrors.Count

        if ($SetErrorVariable) {
            if ($numErrors) {
                Set-Variable -Name "$CertificateErrors" -Value "$localErrors" -Scope Script -Force
            } else {
                Set-Variable -Name "$CertificateErrors" -Value "no errors" -Scope Script -Force
            }

        }

        return $IsValid
    }
}



function Read-CertificateOutput {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$CertificateText
    )

    $cert = [pscustomobject]@{
        Version = $null
        SerialNumber = $null
        SignatureAlgorithm = $null
        Issuer = $null
        ValidFrom = $null
        ValidTo = $null
        Subject = $null
        PublicKeyAlgorithm = $null
        PublicKeySize = $null
        Modulus = ""
        Exponent = $null
        SubjectKeyIdentifier = $null
        AuthorityKeyIdentifier = $null
        AuthorityDirName = $null
        AuthoritySerial = $null
        IsCA = $null
        SignatureAlgorithmTail = $null
        SignatureValue = ""
    }

    $modulusMode = $false
    $sigValueMode = $false

    foreach ($line in $CertificateText) {
        $trim = $line.Trim()

        switch -Regex ($trim) {
            '^Version:\s+(.+)' { $cert.Version = $matches[1] }
            '^Serial Number:\s*$' { continue } # skip line, next one has serial
            '^\s+([a-f0-9:]+)$' {
                if (-not $cert.SerialNumber) {
                    $cert.SerialNumber = $matches[1]
                } elseif ($modulusMode) {
                    $cert.Modulus += $matches[1].Replace(":", "")
                } elseif ($sigValueMode) {
                    $cert.SignatureValue += $matches[1].Replace(":", "")
                }
            }
            '^Signature Algorithm:\s+(.+)' {
                if (-not $cert.SignatureAlgorithm) {
                    $cert.SignatureAlgorithm = $matches[1]
                } else {
                    $cert.SignatureAlgorithmTail = $matches[1]
                }
            }
            '^Issuer:\s+(.+)' { $cert.Issuer = $matches[1] }
            '^\s*Not Before:\s+(.+)' { $cert.ValidFrom = $matches[1] }
            '^\s*Not After\s+:\s+(.+)' { $cert.ValidTo = $matches[1] }
            '^Subject:\s+(.+)' { $cert.Subject = $matches[1] }
            '^\s*Public Key Algorithm:\s+(.+)' { $cert.PublicKeyAlgorithm = $matches[1] }
            '^\s*Public-Key:\s+\((\d+)\s+bit\)' { $cert.PublicKeySize = [int]$matches[1] }
            '^\s*Modulus:' { $modulusMode = $true }
            '^\s*Exponent:\s+(\d+)' { $cert.Exponent = [int]$matches[1]; $modulusMode = $false }
            '^\s*X509v3 Subject Key Identifier:' { $state = 'subjectkeyid' }
            '^\s*X509v3 Authority Key Identifier:' { $state = 'authoritykeyid' }
            '^\s*DirName:(.+)' { $cert.AuthorityDirName = $matches[1].Trim() }
            '^\s*serial:([A-Fa-f0-9:]+)' { $cert.AuthoritySerial = $matches[1] }
            '^\s*CA:\s*TRUE' { $cert.IsCA = $true }
            '^\s*CA:\s*FALSE' { $cert.IsCA = $false }
            '^Signature Value:' { $sigValueMode = $true }
            default {
                if ($state -eq 'subjectkeyid' -and $trim -match '^[A-F0-9:]{20,}$') {
                    $cert.SubjectKeyIdentifier = $trim
                    $state = ''
                }
                elseif ($state -eq 'authoritykeyid' -and $trim -match '^[A-F0-9:]{20,}$') {
                    $cert.AuthorityKeyIdentifier = $trim
                    $state = ''
                }
            }
        }

    }
    $errors = $null
    $IsValid = $cert | Test-CertificateParsedObject -CertificateErrors "myCertErrors"
    $cert | Add-Member -MemberType NoteProperty -Name "IsValid" -Value "$IsValid" -Force
    if ($IsValid) {
        Write-Host "Certificate is valid." -ForegroundColor Green
    } else {
        Write-Host "Certificate is invalid:" -ForegroundColor Red
        $errors = Get-Variable -Name "myCertErrors" -Scope Script -ValueOnly
        $errors | ForEach-Object { Write-Host " - $_" }
    }
    return $cert

}


function Format-CertificateBlock {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Path to original RSA private key (unenforced format)")]
        [string]$CertificateBlock
    )

    try {

        $fivedash = "-----"
        $beginHeader = "-----BEGIN CERTIFICATE-----"
        $endHeader = "-----END CERTIFICATE-----"
        $beginKey = "<ca>"
        $endKey = "</ca>"

        [string]$allrawlines = $CertificateBlock.Replace("`r", '').Replace("`n", '')
        $allrawlines = $allrawlines -replace "`r", '' -replace "`n+", "`n" # Normalize to Unix-style

        # Extract header
        if (!$allrawlines.Contains($beginHeader)) {
            throw "Missing BEGIN header"
        }
        $blocksCount = ($allrawlines.Split($beginHeader)).Count - 1

        $IndexBeginHeader1 = $allrawlines.IndexOf($beginHeader)
        $IndexBeginHeaderAfterDash = $allrawlines.IndexOf($fivedash, $IndexBeginHeader1 + 1) + 5
        $IndexBeginHeader2 = $allrawlines.LastIndexOf($beginHeader)
        $IndexBeginHeader2afterdash = $allrawlines.IndexOf($fivedash, $IndexBeginHeader2 + 1) + 5
        $IndexEndHeader1 = $allrawlines.IndexOf($endHeader)
        $IndexEndHeader2 = $allrawlines.LastIndexOf($endHeader)
        $IndexBeginKey = $allrawlines.IndexOf($beginKey)
        $IndexEndKey = $allrawlines.IndexOf($endKey)
        $i = 1
        $allrawlines = $allrawlines.Insert($IndexBeginHeader1, "`n")
        $allrawlines = $allrawlines.Insert($IndexBeginHeaderAfterDash + $i, "`n")
        $i++
        $allrawlines = $allrawlines.Insert($IndexEndHeader1 + $i, "`n")
        $i++
        if ($blocksCount -eq 2) {
            $allrawlines = $allrawlines.Insert($IndexBeginHeader2 + $i, "`n")
            $i++
            $allrawlines = $allrawlines.Insert($IndexBeginHeader2afterdash + $i, "`n")
            $i++
            $allrawlines = $allrawlines.Insert($IndexEndHeader2 + $i, "`n")
            $i++
        }

        $allrawlines = $allrawlines.Insert($IndexEndKey + $i, "`n")

        $allrawlines = ($allrawlines -split '(.{1,64})' | Where-Object { [string]::IsNullOrEmpty($_) -eq $False }) -join "`n"
        [string[]]$lines = $allrawlines.Split("`n") | Where-Object { [string]::IsNullOrEmpty($_) -eq $False }

        foreach ($l in $lines) {
            Write-Output "$l"
        }
    }
    catch {
        Write-Error "? Error: $_"
    }
}


function Repair-CertificateFile {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Path to original RSA private key (unenforced format)")]
        [string]$InputPath,
        [Parameter(Mandatory = $false)]
        [switch]$Save,
        [Parameter(Mandatory = $false)]
        [switch]$Test
    )
    $OpenSslExe = (get-command 'openssl.exe').Source
    $TempCertFile = "$ENV:Temp\test.pem"
    Remove-Item -Path "$TempCertFile" -Force -Recurse -ErrorAction Ignore | Out-Null
    New-Item -Path "$TempCertFile" -Force -ItemType file -ErrorAction Ignore | Out-Null

    $CertDataFormatted = Format-CertificateBlock $InputPath

    if($Save){
        [string]$OutputPath = Join-Path $((Get-Item $InputPath).DirectoryName) $((Get-Item $InputPath).Basename + "_formated.pem")
        $CertDataFormatted | Set-Content "$OutputPath" -Force -ErrorAction Stop
        Write-Host "✅ PEM format fixed and saved to: $OutputPath" -f DarkRed
    }

    if($Test){
        Set-Content -Path "$TempCertFile"
        [string[]]$CertificateText = & "$OpenSslExe" 'x509' '-in' "$TempCertFile" '-text' '-noout'
        $IsInvalid = $Res[0].StartsWith('Could not find certificate')
        if ($IsInvalid) {
            Write-Error "Invalid Certificate Data"
            return
        }
    
    
        $CertObject = Read-CertificateOutput $CertificateText

        if ($CertObject.IsValid) {
            Write-Host "✅ TESTED! Certificate Block Valid!" -f DarkGreen
        }
    }
    $CertDataFormatted
}


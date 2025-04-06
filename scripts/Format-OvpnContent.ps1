
function Format-Ovpn {
    param (
        [Parameter(Mandatory, HelpMessage = "Unformatted .ovpn config text")]
        [string]$RawText
    )
    $Ovpn = $RawText
    $certPath = ""
    if($RawText.Contains('cert "')){
        $s = $RawText.IndexOf('cert "')
        $e = $RawText.IndexOf('"',$s+7)
        $certPath = $RawText.SubString($s, ($e - $s)+1)
        $Ovpn = $RawText.Replace($certPath, "")
    }


    # Known directives to break on
    [system.Collections.ArrayList]$directives = @(
        "dev", "mode", "mark", "verb", "bind", "port", "route", <# "cert"  processed above #>
        "proto", "rport", "local", "lport", "float", "setenv", "wintun",
        "client", "nobind", "lladdr", "rcvbuf", "sndbuf", "remote", "mssfix",
        "tun-mtu", "iproute", "ifconfig", "ipchange", "dev-type", "dev-node", "link-mtu",
        "mtu-disc", "mtu-test", "fragment", "route-up", "topology", "http-proxy", "txqueuelen",
        "client-nat", "management", "socks-proxy", "persist-key", "proto-force", "route-delay", "fsvpnwintun","preresolve"
        "route-metric", "route-noexec", "socket-flags", "route-nopull", "resolv-retry", "auth-nocache", "route-gateway",
        "tun-mtu-extra", "remote-random", "connect-retry", "replay-window", "route-pre-down", "windows-driver", "push-peer-info",
        "push-peer-info ", "management-hold", "ifconfig-noexec", "ifconfig-nowarn", "allow-pull-fqdn", "remote-cert-tls", "redirect-private",
        "verify-x509-name", "redirect-gateway", "block-outside-dns", "management-client", "allow-compression", "subjectAltNameDNS", "connect-retry-max",
        "http-proxy-option", "remoteauth-nocache", "push-peer-infoverb", "dev-nodepreresolve", "server-poll-timeout", "suppress-timestamps", "show-proxy-settings",
        "mute-replay-warnings", "management-log-cache", "data-ciphers-fallback", "remote-random-hostname", "management-query-remote", "management-query-passwords")
    $indexes = @()
    ForEach($d in $directives){
        $directiveCount = ($Ovpn.Split($d)).Count - 1
        if($directiveCount){
            $from=0
            for($y = 0 ; $y -lt $directiveCount ; $y++){
                $i = $Ovpn.IndexOf($d,$from+1)
                $i_end = $i + $d.Length
                $complete = (($Ovpn[$i_end] -ne '-') -Or ($Ovpn[$i-1] -ne '-') -Or ($Ovpn[$i_end] -ne '/') -Or ($Ovpn[$i-1] -ne '/'))
                if(($i -ne -1) -And ($complete)){
                  $from=$i
                  $indexes += $i    
                }
                
            }
        }
    }
    $sorted_indexes = $indexes | Sort-Object -Descending
    $x = 0
    $FormattedConfig = $Ovpn
    ForEach($index in $sorted_indexes){
        $FormattedConfig = $FormattedConfig.Insert($index, "`n")
        $x++
    }

    $FormattedConfigArray = $FormattedConfig.Split("`n")
    $tmpstr = ''

    [system.Collections.ArrayList]$Sanitize = [system.Collections.ArrayList]::new()
    if(![string]::IsNullOrEmpty($certPath)){
         [void]$Sanitize.Add($certPath)    
    }
    ForEach($line in $FormattedConfigArray){
        $trimmed_line = $line.Replace("-`n","").Replace("`n","").Trim()
        if($trimmed_line.EndsWith('-')){
            $tmpstr = $trimmed_line
            continue;
        }
        if(![string]::IsNullOrEmpty($tmpstr)){
            [void]$Sanitize.Add(($tmpstr + $trimmed_line))    
            $tmpstr=""
        }elseif(![string]::IsNullOrEmpty($trimmed_line)){
            [void]$Sanitize.Add($trimmed_line)    
        }
    }
    $Sanitize
}


function Repair-OvpnSyntax {
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
        
        $beginKey = "<connection>"
        $endKey = "</connection>"
        

        [string]$allrawlines = Get-Content -Path $InputPath -Raw
        [string]$allrawlines = $allrawlines.Replace("`r", '').Replace("`n", '')
        $allrawlines = $allrawlines -replace "`r", '' -replace "`n+", "`n" # Normalize to Unix-style

        # Extract header
        if (!$allrawlines.Contains($beginKey)) {
            throw "Missing BEGIN header"
        }
        $blocksCount = ($allrawlines.Split($beginKey)).Count - 1

        $beginKeyIndex = $allrawlines.IndexOf($beginKey)
        $endKeyIndex = $allrawlines.LastIndexOf($endKey)
        $connblock = $allrawlines.Substring($beginKeyIndex,($endKeyIndex-$beginKeyIndex)+$endKey.Length)
        $allrawlines = $allrawlines.Replace($connblock,'')

        [string[]]$lines = Format-Ovpn $allrawlines


        if($Save){
            [string]$OutputPath = Join-Path $((Get-Item $InputPath).DirectoryName) $((Get-Item $InputPath).Basename + "_formated.ovpn")
            $lines | Set-Content -Path "$OutputPath" -Force
            Write-Host "✅ OVPN format fixed and saved to: $OutputPath" -f DarkRed
            Write-Host "To Test: & 'C:\Program Files\OpenVPN\bin\openvpn.exe' --config `"$OutputPath`"" -f DarkCyan
        }

        foreach ($l in $lines) {
            Write-Output "$l"
        }

    }
    catch {
        Write-Error "? Error: $_"
    }
}

#╔════════════════════════════════════════════════════════════════════════════════╗
#║                                                                                ║
#║   .\scripts\Get-FSecureSiteList.ps1                                            ║
#║                                                                                ║
#╟────────────────────────────────────────────────────────────────────────────────╢
#║   Guillaume Plante <codegp@icloud.com>                                         ║
#║   Code licensed under the GNU GPL v3.0. See the LICENSE file for details.      ║
#╚════════════════════════════════════════════════════════════════════════════════╝



function Get-IpInfo {

    $Data = (iwr 'http://ipinfo.io/json')
    if ($Data.StatusCode -eq 200) {
        Remove-Variable 'NETInfoTable' -ErrorAction ignore -Force
        $NETInfoTable = ($Data.Content | ConvertFrom-Json -AsHashTable)
        New-Variable -Name 'NETInfoTable' -Scope Global -Option ReadOnly, AllScope -Value $NETInfoTable -ErrorAction Ignore
        $NETInfoTable
    }
}


function Get-FsecureSiteListJson {

    # Step 1: Read the registry value
    $regPath = "HKLM:\SOFTWARE\F-Secure\FSVpnSDK"
    $valueName = "SiteList"

    try {
        $rawValue = (Get-ItemProperty -Path $regPath -Name $valueName).$valueName
    } catch {
        Write-Error "Failed to read '$valueName' from registry at '$regPath'"
    }

    # Step 2 & 3: Trim '@ByteArray(' from the start and ')' from the end
    $trimmed = $rawValue.TrimStart('@ByteArray(').TrimEnd(')')

    # Step 4: Save to temp JSON file
    $jsonPath = Join-Path $ENV:TEMP "FSecureVPN-SiteList.json"
    Set-Content -Path $jsonPath -Value $trimmed -Encoding UTF8
    Write-Host "Saved cleaned JSON to: $jsonPath"

    # Step 5: Load and return .sites
    try {
        $JsonData = Get-Content $jsonPath -Raw | ConvertFrom-Json
        return $JsonData
    } catch {
        Write-Error "Failed to parse JSON content."
    }
}

function Get-FsecureSiteListInMyCountry {
    $MyCountry = Get-IpInfo | Select -ExpandProperty country
    
    $Json = Get-FsecureSiteListJson 
    $Json.sites | Where country -eq $MyCountry
}


function Get-FsecureSiteListInMyCountryPorts {
    $MyCountry = Get-IpInfo | Select -ExpandProperty country
    
    $Json = Get-FsecureSiteListJson 
    $Json.sites | Where country -eq $MyCountry | Select -ExpandProperty vset | Select -ExpandProperty v2
}


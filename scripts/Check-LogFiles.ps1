


function Test-LogFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pattern,
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.log"
    )


    try {
        $files = Get-ChildItem -Path "$Path" -File -Filter "*.log" | Select -ExpandProperty Fullname

        Write-Host "Will Monitor those files:"
        $files | % { Write-host " - $_" -f DarkYellow }

        Write-Host "Press 'q' when done monitori files"


        [System.Collections.ArrayList]$JobList = [System.Collections.ArrayList]::new()
        foreach ($file in $files) {
            
            $Job = Start-Job {
                param($file)
                Get-Content -Path $file -Wait -Tail 0 | Where-Object { $_ -match "$Pattern" }
            } -ArgumentList $file

            
            [PsCustomObject]$JobLog = [PsCustomObject]@{
              File = "$file"
              Job = $Job
            }
            [void]$JobList.Add($JobLog)
        }

        do{  
          foreach ($j in $JobList) {
            $jl = $j.Job
            $fn = $j.File
            if($jl.HasMoreData){
                Write-Host "Found Pattern in $fn!"
            }
            Start-Sleep -Milliseconds 50
           }
           Start-Sleep -Milliseconds 50
         } until ([System.Console]::KeyAvailable)

          Write-Host "Stopping jobs"
         Get-Job | Stop-Job

         foreach ($j in $JobList) {
            $jl = $j.Job
            $fn = $j.File
            if($jl.HasMoreData){
                $jl | Receive-Job
            }
            Start-Sleep -Milliseconds 50
           }

    } catch {
        Write-Error $_
    }
}

Test-LogFiles -Path "C:\ProgramData\F-Secure\Log\FSVpnSDK" -Pattern "ERROR"

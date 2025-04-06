

function Get-CurrentConnections {
    $ListeningConnections = (Get-ActiveConnectionsOnly | ? Protocol -EQ TCP) | ? State -EQ LISTENING
    $ListeningConnectionsCount = $ListeningConnections.Count

    $OutgoingConnections = (Get-ActiveConnectionsOnly | ? Protocol -EQ TCP) | ? State -EQ ESTABLISHED
    $OutgoingConnectionsCount = $OutgoingConnections.Count

    $TotalConnections = $OutgoingConnectionsCount + $ListeningConnectionsCount

    [pscustomobject]$o = [pscustomobject]@{}
    $o | Add-Member -MemberType NoteProperty -Name "in" -Value "$ListeningConnectionsCount"
    $o | Add-Member -MemberType NoteProperty -Name "out" -Value "$OutgoingConnectionsCount"
    $o | Add-Member -MemberType NoteProperty -Name "total" -Value "$TotalConnections"

    $o
}

function Compare-SavedConnections ([int]$IdA, [int]$IdB) {
    $ConnectionsOutA = Get-Content -Path "$PWD\Out-$($IdA).json" | ConvertFrom-Json
    $ConnectionsOutB = Get-Content -Path "$PWD\Out-$($IdB).json" | ConvertFrom-Json
    Write-Host "Outgoing: Before $($ConnectionsOutA.Count) / After $($ConnectionsOutB.Count)"
    $ConnectionsInA = Get-Content -Path "$PWD\In-$($IdA).json" | ConvertFrom-Json
    $ConnectionsInB = Get-Content -Path "$PWD\In-$($IdB).json" | ConvertFrom-Json
    Write-Host "Listening: Before $($ConnectionsInA.Count) / After $($ConnectionsInB.Count)"

    $DiffOut = Compare-ConnectionsList $ConnectionsOutA $ConnectionsOutB
    $DiffIn = Compare-ConnectionsList $ConnectionsInA $ConnectionsInB

    $DiffIn
    $DiffOut

}

function Save-CurrentConnections ([int]$Id = 0) {

    $InPath = "$PWD\In-$($Id).json"
    $OutPath = "$PWD\Out-$($Id).json"

    $ListeningConnections = (Get-ActiveConnectionsOnly | ? Protocol -EQ TCP) | ? State -EQ LISTENING
    $JsonDataIn = $ListeningConnections | ConvertTo-Json

    $OutgoingConnections = (Get-ActiveConnectionsOnly | ? Protocol -EQ TCP) | ? State -EQ ESTABLISHED
    $JsonDataOut = $OutgoingConnections | ConvertTo-Json

    $JsonDataOut | Set-Content -Path "$OutPath"
    $JsonDataIn | Set-Content -Path "$InPath"

    Write-Host "saved $($ListeningConnections.Count) listening connections in $InPath"
    Write-Host "saved $($OutgoingConnections.Count) outgoing connectionsin $OutPath"
}


function Compare-ConnectionsList ($ListA, $ListB) {
    # Do the comparison
    $diff = Compare-Object -ReferenceObject $ListA -DifferenceObject $ListB -Passthru

    # Show added connections (present in B but not in A)
    $added = $diff | Where-Object { $_.SideIndicator -eq '=>' }

    # Show removed connections (present in A but not in B)
    $removed = $diff | Where-Object { $_.SideIndicator -eq '<=' }
    $addedlist = @()
    $removedlist = @()
    foreach ($c in $added) {
        [pscustomobject]$o = [pscustomobject]@{}
        $direction = if ($c.State -eq 'ESTABLISHED') { "outgoing" } elseif ($c.State -eq 'LISTENING') { "incomming" }
        $o | Add-Member -MemberType NoteProperty -Name "type" -Value "added"
        $o | Add-Member -MemberType NoteProperty -Name "direction" -Value "$direction"
        $o | Add-Member -MemberType NoteProperty -Name "connection" -Value "$("$($c.LocalAddress)" + "=>" + "$($c.RemoteAddress)")"
        $o | Add-Member -MemberType NoteProperty -Name "process" -Value "$($c.ProcessName)"
        $addedlist += $o

    }
    foreach ($c in $removed) {
        [pscustomobject]$o = [pscustomobject]@{}
        $direction = if ($c.State -eq 'ESTABLISHED') { "outgoing" } elseif ($c.State -eq 'LISTENING') { "incomming" }
        $o | Add-Member -MemberType NoteProperty -Name "type" -Value "added"
        $o | Add-Member -MemberType NoteProperty -Name "direction" -Value "$direction"
        $o | Add-Member -MemberType NoteProperty -Name "process" -Value "$("$($c.ProcessName)" + " (" + "$($c.ProcessId)" + ")")"
        $o | Add-Member -MemberType NoteProperty -Name "connection" -Value "$("$($c.LocalAddress)" + "=>" + "$($c.RemoteAddress)")"
        $removedlist += $o
    }

    $alldiff = $addedlist + $removedlist
    $alldiff
}



function Start-TcpConnectionsTest{
    Clear-Host

    Write-Host "=====================================================" -f DarkCyan
    Write-Host " CONNECTION TEST - DIFFERENCE BETWEEN TWO SNAPSHOTS  " -f DarkCyan
    Write-Host "  --- press any key to take the first snapshot ---   " -f DarkCyan
    Write-Host "=====================================================" -f DarkCyan
    Read-Host "Ready!" -f DarkYellow
    Save-CurrentConnections(0)
    [datetime]$first=[datetime]::Now
    $strtime1 = $first.GetDateTimeFormats()[22]
    Write-Host "save 1st connections at $strtime1" -f DarkCyan

    Write-Host "=====================================================" -f Magenta
    Write-Host "   --- press any key to take the 2nd snapshot ---    " -f Magenta
    Write-Host "=====================================================" -f Magenta
    Read-Host "Ready!" -f Green
    Save-CurrentConnections(1)
    [datetime]$second=[datetime]::Now
    $strtime2 = $second.GetDateTimeFormats()[22]
    Write-Host "save 2nd connections at $strtime2" -f DarkCyan

    Compare-SavedConnections 0 1
}
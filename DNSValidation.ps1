Import-Module PSExcel
Import-XLSX -Path L:\HomeLabServers.xlsx -OutVariable HomeLabServers.xlsx | Out-Null

$FinalResults = [Ordered]@{}
$FinalResults2 = [Ordered]@{}

Foreach ($Server in ${HomeLabServers.xlsx}.hostname){
 $FinalResults.$Server = $Null
 $FinalResults2.$Server = $Null
    Test-NetConnection -ComputerName $Server -OutVariable NetConnection -WarningAction SilentlyContinue | out-null
    if ($NetConnection.PingSucceeded -eq $false){
        Write-Host "Ping to $Server failed."
        $FinalResults.$Server = 'Failed'
        $finalResults2.$Server = 'Not Resolved'
    }
    else {
        $FinalResults.$Server = 'Succeeded'
        $FinalResults2.$Server =$NetConnection.ResolvedAddresses.maptoIPv4().ipaddresstostring
    }

 
}
$FinalResults
$FinalResults2

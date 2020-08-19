Function Get-SM.CitrixUserConnectionLog { 
    [cmdletbinding()]
    Param( [Parameter(mandatory=$True)][String[]]$Names )
    

    Foreach ($Name in $Names) {
        $ConnectionInfo = Get-BrokerConnectionLog -BrokeringUsername "SM\$Name" -MaxRecordCount 5000
                
        Foreach ($Connection in $ConnectionInfo) {
            $Props = [Ordered]@{
                Account = $Name ;
                CitrixHost = $Connection.MachineDNSName
                StartTime = $Connection.EstablishmentTime
                EndTime = $Connection.EndTime
                SessionLength = if ($Connection.Endtime -eq $Null ) {Write-Output "Active Session"} Else {$Connection.EndTime - $Connection.EstablishmentTime}
                ConnectionFailureReason = $Connection.ConnectionFailureReason
                }
            $obj = New-Object -TypeName PSObject -Property $props
            $Obj 
            }
        } 
}

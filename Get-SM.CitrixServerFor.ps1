Function Get-SM.CitrixServerFor { 
    [cmdletbinding()]
    Param( [Parameter(mandatory=$True)][String[]]$Names )
    

    Foreach ($Name in $Names) {
        $SessionInfo = Get-BrokerSession -UserFullName $Name -MaxRecordCount 5000 | 
        Select UserFullName, SessionState, StartTime, ClientAddress, ClientVersion, DesktopGroupName, DNSName,  AgentVersion

        $Props = [Ordered]@{
            Account = $Name ;
            State = if ($SessionInfo.SessionState -eq $null) {Write-Output 'Not Connected'} Else {$SessionInfo.SessionState}
            StartTime = $SessionInfo.StartTime
            ClientIP = $SessionInfo.ClientAddress
            ClientVersion = $SessionInfo.ClientVersion
            DeliveryGroup = $SessionInfo.DesktopGroupName
            CitrixHost = $SessionInfo.DNSName
            AgentVersion = $SessionInfo.AgentVersion
            }
        $obj = New-Object -TypeName PSObject -Property $props
        $Obj

        }
}

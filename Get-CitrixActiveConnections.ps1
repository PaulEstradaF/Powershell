Function Get-CitrixActiveConnections {
    [Cmdletbinding()]
    Param([Switch]$ShowConnectionsByServer
    )
    if ($ShowConnectionsByServer) {
        Get-BrokerSession -MaxRecordCount 5000 | Where SessionState -eq Active -OutVariable BrokerSessions | Group DNSName |
                            Select @{n='CitrixHost';e={$_.Name}},@{n='Sessions';e={
                                Foreach ($Server in $_.Name) {$CheckIfInMaintenaceMode = Get-BrokerMachine "SM\$($Server.Split('.domain.lan')[0])" |
                                    Select InMaintenanceMode
                                    if ($CheckIfInMaintenaceMode.InMaintanceMode -eq $True) {
                                    "InMaintenanceMode"
                                    } else {$_.Count}}
                            }}
        } Else {
            Get-BrokerSession -MaxRecordCount 5000 | Where SessionState -eq Active | Group 'DesktopGroupName' |
                                Select @{n='DeliveryGroup';e={$_.Name}}, @{n='Sessions';e={$_.Count}}

            Write-Output ""; $Total = $Null 
            Get-BrokerSession -MaxRecordCount 5000 | Where SessionState -eq Active | Group 'DesktopGroupName' | 
                                Select @{n='DeliveryGroup';e={$_.Name}}, @{n='Sessions';e={$_.Count -as [int]}} |
                                    Foreach {$total += $_.Sessions}; $total |
                                        Select @{n='Total Active Citrix Connections';e={$total}} | FL
        }
}

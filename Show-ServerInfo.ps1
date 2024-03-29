function Show-ServerInfo {
    Start-Process Powershell.exe -ArgumentList {
        [Console]::WindowHeight='25'
        [Console]::WindowWidth='55'
        [Console]::BackgroundColor='Black'    
        Cls
        Write-Host " _____________________________________________________ " -BackgroundColor DarkRed -ForegroundColor White
        Write-Host ' --------------Conversion Project------------- ' -BackgroundColor DarkRed -ForegroundColor White
        Write-Host " ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ " -BackgroundColor DarkRed -ForegroundColor White
        Write-Host "                                                       "
        Write-Host " Current Server Information                            " -BackgroundColor DarkRed -ForegroundColor White
    
        $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ComputerName (hostname)
        $NetworkAdapterInfo = Get-NetIPAddress -InterfaceAlias Ethernet0
        $NetworkAdapterGatewayInfo = Get-NetIPConfiguration | select -ExpandProperty Ipv4DefaultGateway
        $NetworkAdapterDNSInfo = Get-DnsClientServerAddress -InterfaceAlias Ethernet0 
        $DHCPServerInfo = Get-DhcpServerv4Scope | Select *
        $DHCPServerDNSInfo = Get-DhcpServerv4OptionValue -ComputerName $env:COMPUTERNAME | select *
    
        $Props = @{ 'ServerName'=$ComputerSystem.Name ;
                    'Domain'=$ComputerSystem.Domain ;
                    'NetworkAdapterName'=$NetworkAdapterInfo.InterfaceAlias ;
                    'NetworkAdapterIPAddress'=$NetworkAdapterInfo.IPAddress ;
                    'NetworkAdapterGateway'=$NetworkAdapterGatewayInfo.NextHop ;
                    'NetworkAdapterDNS'=$NetworkAdapterDNSInfo.ServerAddresses ;
                    'DhcpScopeName'=$DHCPServerInfo.Name ;
                    'DhcpScopeID'=$DHCPServerInfo.ScopeID ;
                    'DhcpScopeStartRange'=$DHCPServerInfo.StartRange ;
                    'DhcpScopeEndRange'=$DHCPServerInfo.EndRange ;
                    'DhcpScopeSubnetMask'=$DHCPServerInfo.SubnetMask ;
                    'DhcpScopeState'=$DHCPServerInfo.State ;
                    'DhcpScopeDns'=$DHCPServerDNSInfo.value ;
                  }
        $obj = New-Object -TypeName PSObject -Property $Props | 
               Select Servername, Domain, NetworkAdapterName, NetworkAdapterIpAddress, NetworkAdapterGateway, NetworkAdapterDNS, `
               DhcpScopeName, DhcpScopeID, DhcpScopeStartRange, DhcpScopeEndRange, DhcpScopeSubnetMask, DhcpScopeState, DhcpScopeDNS
           
        Write-output $obj 
        Pause
        }
        
}

Show-ServerInfo 

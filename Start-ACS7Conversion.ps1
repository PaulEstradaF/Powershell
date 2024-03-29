WorkFlow Start-ACS7Conversion {
    [CmdletBinding()]
    Param(       
        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the domain you will be joining. Example: Domain.Lan")]
        [String]$NewDomain,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the current Server Name. Example: ServerName")]
        [string]$OldName,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the new Server Name. Example: ServerName")]
        [string]$NewName,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter your domain credentials with Administrator access.")]
        [System.Management.Automation.PSCredential]$AdminCred,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the Local credentials with Administrator access.")]
        [System.Management.Automation.PSCredential]$LocalCred,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the NIC name. Get-NetAdapter | Select Name")]
        [String]$NicName,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the current server IP Address.",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$OldIP,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the current server Gateway IP Address.",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$OldGW,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the NEW IP Address.",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$NewIP,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the NEW Gateway IP Address.",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$NewGW,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the name of Dhcp Scope you are creating.")]
        [String]$NewDhcpScopeName,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the Start Range for the NEW Dhcp Scope. Example: xxx.xxx.x.100",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$DHCPStartRange,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the End Range for the NEW Dhcp Scope. Example: xxx.xxx.5.100",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$DHCPEndRange,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the Subnet Mask for the NEW Dhcp Scope. Example: 255.255.255.0",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$DhcpSubMask,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the Primary DNS Address for the NEW Dhcp Scope.", 
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$DhcpDNS1,

        [Parameter(Mandatory=$True,
                   HelpMessage="Enter the Secondary DNS Address for the New Dhcp Scope.",
                   ValueFromPipeLineByPropertyName=$True,
                   Position=0)]
        [ValidateScript({$_ -match [ipaddress]$_})]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String]$DhcpDNS2,

        [Switch]$ShowProgress,

        [Switch]$LeaveDomain,

        [Switch]$JoinNewDomain,

        [Switch]$ReplaceNICInfo,

        [Switch]$NewDhcpServerScope,

        [Switch]$RenameServer
   )

    <#Removes the current IP and Gateway addresses#>
    if($ShowProgress)   { Write-Progress -Activity "Removing The Current IP and Gateway Addresses."}
    if($ReplaceNICInfo) { Remove-NetIPAddress $OldIP  -DefaultGateway $OldGW -Confirm:$false -Verbose }

    Checkpoint-Workflow 
    
    <#Sets New ip, subnet, and gateway addresses#>
    if($ShowProgress)   { Write-Progress -Activity "Adding New IP and Gateway Addresses" }
    if($ReplaceNICInfo) { New-NetIPAddress -InterfaceAlias "$NicName" -IPAddress $NewIp -PrefixLength 24 `
                          -DefaultGateway $NewGW -Verbose }
    
    Checkpoint-Workflow
   
   <#Creates a new DHCP Scope, Names it, Sets Range, Sets Subnet, Activates#>
    if($NewDhcpServerScope) { if($ShowProgress) { Write-Progress -Activity "Creating new Dhcp Server Scope." }
                              Add-DHCPServerv4Scope -Name $NewDhcpScopeName -StartRange $DhcpStartRange `
                              -EndRange $DhcpEndRange -State Active -SubnetMask $DhcpSubMask -Verbose ;
                               
                               Checkpoint-Workflow

                              if($ShowProgress) { Write-Progress -Activity "New scope created Successfully.
                                                  Adding DNS information to DHCP Scope" }
                              Set-DhcpServerv4OptionValue -OptionId 6 -value $DhcpDNS1, $DhcpDNS2 `
                              -Confirm:$false -Verbose ;
                              
                              Checkpoint-Workflow}
        

    if($LeaveDomain)    { if($ShowProgress) { Write-Progress -Activity "Leaving current domain." }
                          Remove-Computer -LocalCredential $LocalCred -UnjoinDomainCredential $AdminCred `
                          -WorkgroupName WORKGROUP -Force -Verbose ;
                          Checkpoint-Workflow}

    if($RenameServer)   { Rename-Computer -NewName $newname -LocalCredential $LocalCred -Verbose }

    if($JoinNewDomain)  { Add-Computer -PSComputerName $OldName  -LocalCredential $LocalCred `
                          -DomainName $NewDomain -Credential $AdminCred -NewName $NewName -Verbose;
                          
                          if($Showprogress) { Write-Progress -Activity "Successfully Renamed $oldname to $newname `
                                              and joined it to a new domain, $NewDomain." } }
    Checkpoint-Workflow
}
               
Write-Verbose "Starting  Conversion Changes."
                 
Start-ACS7Conversion  -NewDomain None `
                      -AdminCred Dmi\Administrator `
                      -LocalCred Administrator `
                      -NicName ethernet0 `
                      -OldIP 192.168.0.200 `
                      -OldGW 192.168.0.1 `
                      -NewIp 192.168.0.200 `
                      -NewGW 192.168.0.1 `
                      -NewDhcpScopeName FakeName `
                      -DHCPStartRange 192.168.0.233 `
                      -DHCPEndRange 192.168.0.244 `
                      -DhcpSubMask 255.255.255.0 `
                      -DhcpDNS1 1.1.1.1 `
                      -DhcpDNS2 8.8.8.8 `
                      -ShowProgress `
                      -RenameServer 

Write-Verbose "Rollout Workflow completed successfully."

Pause

$Error | Out-File C:\users\Administrator\Desktop\error.txt

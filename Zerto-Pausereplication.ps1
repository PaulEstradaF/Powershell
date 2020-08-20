<#.Synopsis
    Pauses replication when Nagios is reporting that a specific network
    node in Yosemite Wholesale or Roseville DC is using a lot of 
    incoming bandwidth.
.DESCRIPTION
    The thresholds for bandwidth limit and time to wait before pausing
    are configured under ## Settings. This script creates a function, 
    Get-SM.ReplicationStatus, that uses Get-SM.NagiosXiAPI, to check 
    the current status of the Nagios services that were specified:
    YW_TPAC-Main-2951 : GigabitEthernet0/2 DS1IT-xxxxxxxx Bandwidth
    ROS-TPAC-MAIN-2951.Network.Company.com : GigabitEthernet0/1 Bandwidth
    The function creates custom objects from the information gathered accessing
    the Nagios APIs. The script is preconfigured to have the Status as Good.
    While the status is Good it runs through a loop that checks Nagios to see
    what the current bandwidth is. If the incoming bandwidth is under the
    threshold, it will run indefinitely. If it is detected that the bandwidth
    is above the threshold it will print out a message identifying which 
    node is having an issue and change the status to 'OverLimit'. While the
    status is OverLimit there is a timer that starts and checks the difference
    in time from when issue started to current cycle in the loop. If that 
    time difference reaches the threshold an email can be sent to whatever
    addresses is requested. 
    Work in progress:
    Outgoing email notification needs to be configured.
    Logging.
.Notes
    This script requires API access to Nagios using a customized version of the
    MrANagios modules. The modified function, Get-SM.NagiosXIApi, should be 
    located in '$ENV:ProgramFiles\WindowsPowershell\Modules\'. This also script
    also needs to have the Zerto.PS.Commands installed using an exe that was 
    downloaded from a link provided by m.
    Information on the powershell commands:
    https://s3.amazonaws.com/zertodownload_docs/5.5U3/Zerto%20Virtual%20Replication%20PowerShell%20Cmdlets%20Guide.pdf
 #>

## Temporary workaround to bypass the expired ssl cert on Nagios.  ****************************
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3,`
                                              [Net.SecurityProtocolType]::Tls, `
                                              [Net.SecurityProtocolType]::Tls11, `
                                              [Net.SecurityProtocolType]::Tls12

## End of temporary workaround ****************************************************************

## Settings ####################################################################################
$KeyFullPath   = "C:\Program Files\Zerto\Zerto Virtual Replication\ESK"                                                  
$CredentialPath= "C:\Path\To\Zerto\Data\"                                               
$Creds = Import-Credential -CredentialFilePath $CredentialPath -EncryptionKeyPath $KeyFullPath 
                                                                                               
# The bandwidth threshold in Mbps                                                              
[decimal]$BandwidthThreshold = 40                                                              
                                                                                               
# Length of time to wait over threshold before pausing replication                             
[int]$TimeThreshold = 2                                                                        
[int]$TimeThresholdPaused = 2                                                                  
[int]$TimeThresholdRecovering = 2                                                              

#Log information
$Log = '\\Path\To\File\Zerto\Logs-PauseReplication\PauseReplication-RoseOnly.txt'
$CurrentTime = Get-Date
$LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Starting Script PauseReplication-RoseOnly.ps1. "
$Logthis | Out-File $Log -Append

# Loads the required module.                                                                    
Import-Module 'C:\Program Files\WindowsPowerShell\Scripts\Get-SM.NagiosXiAPI.ps1'              
## End of Settings ############################################################################

Function Get-SM.NagiosBandwidthStatus {
    # Nodes to Monitor. Uses the Nagios Host Name of the devices as well as the Service Name of the service we need monitored
    $Nodes = @{
        Rose = @{
            "NagiosHostName"="ROS-TPAC-MAIN-2951.Network.Company.com";
            "NagiosServiceName"="GigabitEthernet0/1 Bandwidth"
            "VPG"="Roseville DC"}
    }

    Foreach ($Node in $Nodes.Keys) {
        $NagiosHost    = $Nodes[$Node]['NagiosHostName']
        $NagiosService = $Nodes[$Node]['NagiosServiceName']
        $Expression    = "Get-SM.NagiosXIApi -Resource objects/servicestatus -Query `'host_name=$NagiosHost&name=$NagiosService`' | Select -Expand servicestatus "
        $CheckNagios   = Invoke-Expression $Expression 
        $Props = [ordered]@{
            LastUpdated    = $CheckNagios.status_update_time
            NagiosHost     = $CheckNagios.host_name
            NagiosService  = $CheckNagios.name
            VPG            = $nodes["$node"]['vpg']
            'BW-In(Mbps)'  = [decimal]$CheckNagios.Status_Text.Split()[5].TrimEnd('Mbps')
            'Bw-Out(Mbps)' = [decimal]$CheckNagios.Status_Text.Split()[7].TrimEnd('Mbps')     
            } # End of props
        $Obj = New-Object -TypeName PSObject -Property $Props; $obj
        }
} # End of Function

$Status = 'Good'
While ($Status -eq 'Good') {

    $AllCurrentStatus = Get-SM.NagiosBandwidthStatus
    $StartTimeGood = Get-Date
    
    Foreach ($CurrentStatus in $AllCurrentStatus) {

        if ( ($CurrentStatus).'Bw-Out(Mbps)' -gt $BandwidthThreshold ) {
            $StartTimeOverLimit = Get-Date
            $Status = 'OverLimit'         
            # If the status is Over Limit This will While Loop will process
            While ($Status -eq 'OverLimit') {
                #log
                $CurrentTime = Get-Date
                $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Current Status is OverLimit. Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
                $Logthis | Out-File $Log -Append
                #
                $props = [ordered]@{
                    'Status' = $Status
                    'Start' = $StartTimeOverLimit.ToLongTimeString()
                    'Current' = (Get-Date).ToLongTimeString()
                    'BW-Out' = $CurrentStatus.'BW-Out(Mbps)'
                    'BWThreshold(Mbps)' = $BandwidthThreshold
                    NagiosHost = $CurrentStatus.NagiosHost
                    NagiosService = $CurrentStatus.NagiosService
                    VPG = $CurrentStatus.VPG
                    }
                $OverLimitobj = New-Object -TypeName psobject -Property $Props 
                $OverLimitobj | FT Status,Start,Current,'BW-Out',VPG 

                $CurrentTime = Get-Date
                $TimeDiffOverLimit = $CurrentTime - $StartTimeOverLimit
                Start-sleep -Seconds 10

                ## If the status is overlimit for the length of the Time Threshold the Status gets chaned to Paused
                if ([int]$TimeDiffOverLimit.minutes -ge [int]$TimeThreshold) {
                    $CurrentTime = Get-Date
                    Write-Host "[$($CurrentTime.ToLongTimeString())] The time threshold of $TimeThreshold minute was met. " -ForegroundColor Yellow -NoNewline
                    Write-Host "Changing status to paused." -ForegroundColor Yellow
                    $Status = 'Paused'                  
                                                    
                    $StartTimePaused = Get-Date                             
                    Try { 
                        $CurrentTime = Get-Date
                        Write-Host "[$($CurrentTime.ToLongTimeString())] Connecting to Zerto API." -ForegroundColor Yellow -OutVariable LogThis
                        $LogThis | Out-File $Log -Append
                        Connect-ZertoServer -zertoServer IPADDRESS -zertoPort Port -credential $Creds -OutVariable ConnectToZerto
                        }
                    Catch { Write-Host "Could not connect to the Zerto API" }

                    #This will be the command to Pause.
                    
                    ## log
                    $CurrentTime = Get-Date
                    $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Pausing Replication for $($OverLimitObj.Vpg). Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
                    $Logthis | Out-File $Log -Append
                    ##  
                    Suspend-ZertoVpg -vpgName $OverLimitobj.VPG -Verbose 

                    #disconnect from zerto after Pausing
                    ##log
                    $CurrentTime = Get-Date
                    $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Disconnecting from Zerto API."
                    $Logthis | Out-File $Log -Append
                    # # 

                    Disconnect-ZertoServer
                    
                    While ($Status -eq 'Paused') {
                        $CurrentStatusPaused = Get-SM.NagiosBandwidthStatus | Where NagiosHost -EQ $CurrentStatus.NagiosHost
                        #log
                        $CurrentTime = Get-Date
                        $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Current Status is Paused. Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
                        $Logthis | Out-File $Log -Append
                        # 

                        #If the object is paused and bandwidth is over the threshold
                        if ($CurrentStatusPaused.'BW-Out(Mbps)' -gt $BandwidthThreshold) {
                            $CurrentTime = Get-Date
                            $props = [ordered]@{
                                'Status' =$Status
                                'Start' = $StartTimePaused.ToLongTimeString()
                                'Current' = (Get-Date).ToLongTimeString()
                                'BW-Out' = $CurrentStatusPaused.'BW-Out(Mbps)'
                                'BWThreshold(Mbps)' = $BandwidthThreshold
                                NagiosHost = $CurrentStatusPaused.NagiosHost
                                NagiosService = $CurrentStatusPaused.NagiosService
                                VPG = $CurrentStatusPaused.VPG
                                }
                            $PausedObj = New-Object -TypeName psobject -Property $Props 
                            $PausedObj | FT Status,Start,Current,'BW-Out',VPG 
                            Start-Sleep -Seconds 10
                            }
                        # If the object is paused the the bandwidth is now under the threshold
                        Else {
                            $CurrentTime = Get-Date
                            Write-Host "[$($CurrentTime.ToLongTimeString())] " -NoNewline
                            Write-host "Outgoing Bandwidth for $($CurrentStatusPaused.vpg) is below the threshold of $BandwidthThreshold Mbps."
                            Write-Host "Changing Status to 'Recovering."
                            $Status = 'Recovering'
                            $StartTimeRecovering = Get-Date

                            # While Status is Recovering
                            While ($Status -eq 'Recovering') {
                                $CurrentStatusRecovering = Get-SM.NagiosBandwidthStatus | Where NagiosHost -EQ $CurrentStatus.NagiosHost 
                                #log
                                $CurrentTime = Get-Date
                                $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Status was below the bw freshold for $TimeThresholdRecovering minutes Status Changed to Recovering. Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
                                $Logthis | Out-File $Log -Append
                                # 
                                
                                $props = [ordered]@{
                                    'Status' = $Status
                                    'Start' = $StartTimeRecovering.ToLongTimeString()
                                    'Current' = (Get-Date).ToLongTimeString()
                                    'BW-Out' = $CurrentStatusRecovering.'BW-Out(Mbps)'
                                    'BWThreshold(Mbps)' = $BandwidthThreshold
                                    NagiosHost = $CurrentStatusRecovering.NagiosHost
                                    NagiosService = $CurrentStatusRecovering.NagiosService
                                    VPG = $CurrentStatusRecovering.VPG
                                    }
                                $RecoveringObj = New-Object -TypeName psobject -Property $Props 
                                $RecoveringObj | FT Status,Start,Current,'BW-Out',VPG 
                                $CurrentTime = Get-Date
                                $TimeDiffRecovering = $CurrentTime - $StartTimeRecovering
                                Start-Sleep -Seconds 10

                                #If it has been in the Recovering status for more than the threshold, it changes the status back to Good
                                if ([int]$TimeDiffRecovering.minutes -ge [int]$TimeThresholdRecovering) {
                                    $CurrentTime = Get-Date
                                    Write-Host "[$($CurrentTime.ToLongTimeString())]" -NoNewline
                                    Write-Host " Outgoing bandwidth for $($CurrentStatus.NagiosHost) has been below threshold for $TimeThresholdRecovering minutes. Changing status to Good." -ForegroundColor Green
                                    Write-Host "Resuming replication." -ForegroundColor Green
                                    #log
                                    $CurrentTime = Get-Date
                                    $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Status has been Recovering for over $TimeThresholdRecovering. Changing status to Good. Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
                                    $Logthis | Out-File $Log -Append
                                    # 


                                    Connect-ZertoServer -zertoServer IPADDRESS -zertoPort 9669 -credential $Creds 
                                    
                                    #log
                                    $CurrentTime = Get-Date
                                    $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongtTimeString())] Resuming $($RecoveringObj.Vpg). Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
                                    $Logthis | Out-File $Log -Append
                                    # 

                                    Resume-ZertoVpg -vpgName $RecoveringObj.Vpg -Verbose
                                    Write-output ""
                                    $Status = 'Good'
                                    Disconnect-ZertoServer -Verbose                               
                                    } 
                                } 
                            } 
                        }  
                    }
                }        
            } 
        Else { 
            $CurrentStatusGood = Get-SM.NagiosBandwidthStatus | Where NagiosHost -EQ $CurrentStatus.NagiosHost 
            $props = [ordered]@{
                'Status' = $Status
                'Start' = $StartTimeGood.ToLongTimeString()
                'Current' = (Get-Date).ToLongTimeString()
                'BWThreshold(Mbps)' = $BandwidthThreshold
                'BW-Out' = $CurrentStatusGood.'BW-Out(Mbps)'
                NagiosHost = $CurrentStatusGood.NagiosHost
                NagiosService = $CurrentStatusGood.NagiosService
                VPG = $CurrentStatusGood.VPG
                }
            $GoodObj = New-Object -TypeName psobject -Property $Props 
            $GoodObj | FT Status,Start,Current,'BW-Out',VPG

            #log
            $CurrentTime = Get-Date
            $LogThis = "[$($CurrentTime.ToShortDateString()) $($CurrentTime.ToLongTimeString())] Current Status is Good. Bandwidth Out: $($CurrentStatus.'Bw-Out(Mbps)')Mbps."
            $Logthis | Out-File $Log -Append
            #
            Start-Sleep -Seconds 5
            } 
        }
}

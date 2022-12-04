Function Delete-CitrixProfile {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [String[]]$Profile,
        [Parameter(Mandatory=$True,ValueFromPipeLine=$True)]
        [ValidateSet('Value1','Value2','Value3','Value4','Value5')]
        [String[]]$Banner,
        [Alias("Username")]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty 
        )

    BEGIN {
        ## Import necessary modules
        Import-Module -Name ImportExcel

        ##  Imports Citrix groups from excel sheet
        Import-Excel -Path L:\HomeLabCitrixServers.xlsx -OutVariable CitrixServers.xlsx | Out-Null

        $Path = 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\ProfileList\'

        ##  This grabs the contents of the $Path but only selects the Name property. It uses that to build
         #  the profile list.
        $ProfileList = (Get-ChildItem -Path 'HKLM:\software\Microsoft\Windows NT\CurrentVersion\ProfileList\').Name  
    
        #
        $FinalResults = foreach ($Prof in $ProfileList) {
            $SID = $Prof.Split('\')[6]
            $KeyLocation = $Path + $SID
            Get-ItemProperty -Path $KeyLocation | Select-Object ProfileImagePath -OutVariable KeyValue | Out-Null
            $CurrentProfile = $KeyValue.ProfileImagePath.Split('\')[2]

            ##  This consolidates the information gathered above and turns it into an array with custom properties
            $Props = [Ordered]@{
                Profile = $CurrentProfile;
                ProfilePath=$($KeyValue.ProfileImagePath);
                RegKeyLocation=$Keylocation;
                SID = $SID }

            #  This takes the $props and turns them into a custom ps object
            $Obj = New-Object -TypeName PSObject -Property $Props
        
            #  This adds the individual object to $FinalResults which is an array of the individual objects
            $Obj           
            }
        Write-Host "  This is after the foreach loop." -ForegroundColor Blue
        }

    PROCESS { 
        $FinalResults.
        $ServersinBanner = (${CitrixServers.xlsx} | Where {$_.Banner -eq $Banner}).ServerName
        #$Process = 
        foreach ($Server in $ServersinBanner) {

            Invoke-Command -ComputerName $Server -ScriptBlock {`
                            Write-Host "This is from inside $Env:COMPUTERNAME" `
                            } -Credential $Credential

            Invoke-Command -ComputerName $Server -ScriptBlock {`
                            Write-Host "Second InvokeCommand" `
                            } -Credential $Credential
            }
        #$Process

        }

}

 Function Get-HDRebootCount{ 
    [CmdletBinding()]
    param (
    [Parameter(Mandatory=$True,
    ValueFromPipeLine=$True)]
    [String[]]$RBCHostnames,

    [Parameter(Mandatory=$True)]
    [String]$FromDate,

    [Parameter(Mandatory=$True)]
    [String]$ToDate,

    [Parameter(Mandatory=$True)]
    [Alias("Username")]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credential = [System.Management.Automation.PSCredential]::Empty 
    )
                
    foreach ($RBCHostname in $RBCHostNames) {
	    Get-WinEvent -Filterhashtable @{logname='System'; 
									    id='12';} `
					    -ComputerName $RBCHostName -Credential $Credential |
	    Where {$_.TimeCreated -gt "$FromDate" -and $_.TimeCreated -lt "$ToDate"} |
	    Select Timecreated, ID, MachineName, Message
        }
}

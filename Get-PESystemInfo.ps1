$PEErrorLogPreference = "C:\Errors.txt"

function Get-PESystemInfo {
    <#
    .Synopsis
    Queries important computer information from a single register.
    .DESCRIPTION
    Queries OS and hardware information from a single register. This
    utilizes WMI, so the appropriate WMI ports must be open and you must 
    be an Admin on the Remote Machine.
    .PARAMETER ComputerName
    The name of the register to query. Accepts multiple values 
    and accepts pipeline input
    .PARAMETER IPAddress
    The IP Address to query. Accepts multiple values but not pipeline input.
    .PARAMETER ShowProgress
    displays a progress bar showing current operations and percent complete.
    Percentage will be inaccurate when piping computer names into the command.
    .EXAMPLE
    Get-PESystemInfo -ComputerName whaterver
    This will query information from the computer whatever.
    .EXAMPLE
    Get-PESystemInfo -ComputerName Whatever | Format-Table *
    This will display the information in a table.
    .EXAMPLE
    Get-PESystemInfo -IPAddress 10.0.0.1, 10.20.30.40
    Queries computer by IP address instead of computer name. Does not 
    accept pipeline input.
    .LINK
    
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,
                  ValueFromPipeLine=$True,
                  ValueFromPipelineByPropertyName=$True,
                  ParameterSetName='ComputerName',
                  HelpMessage="Computer name to query by WMI.")]
        [Alias('hostname')]
        [ValidateLength(4,15)]
        [String[]]$ComputerName, 

        [Parameter(Mandatory=$True,
                   ParameterSetName='IP',
                   HelpMessage="IP Address to query via WMI.")]
        [ValidatePattern('\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}')]
        [String[]]$IPAddress,
   
        [Parameter()]
        [String]$ErrorLogFilePath = $PEErrorLogPreference,

        [switch]$ShowProgress 
    )
    BEGIN {
        if ($PSBoundParameters.ContainsKey('ipaddress')) {
            Write-Verbose "Putting IP addresses into variable."
            $computername = $IPAddress
        }
        if ($ComputerName -ne $null) {
            #We got input via parameter
            $each_computer = (100 / ($computername.count) -as [int])
            $pipeline_mode = $false
        } else {
            $each_computer = 100
            $pipeline_mode = $true
        }
        #Set the current Completion to zero as a starting point.
        $Current_complete = 0
        Del $ErrorLogFilePath -ErrorAction SilentlyContinue
    }
    PROCESS {
        foreach ($Computer in $Computername) {

            if ($computer -eq '127.0.0.1') {
                Write-Warning "Connecting to local computer loopback!"
            }

            if ($ShowProgress) { Write-Progress -Activity "Working on $Computer." -PercentComplete $Current_Complete }

            Write-Verbose "Connecting via WMI to $computer."
            if ($ShowProgress) { Write-Progress -Activity "Working on $Computer." -CurrentOperation "Operating System." -PercentComplete $Current_Complete }
            try {
                $Everything_is_ok = $True
                $os = Get-WmiObject -class win32_operatingsystem -ComputerName $computer -ErrorAction Stop
            } catch {
                Write-Warning "$computer failed - Logging computer name to $ErrorLogFilePath"
                $computer | Out-File $ErrorLogFilePath -Append
                $Everything_is_ok = $false
            }

            if($Everything_is_ok) {
                if ($ShowProgress) { Write-Progress -Activity "Working on $Computer." -CurrentOperation "Computer System." -PercentComplete $Current_Complete }
                $cs = Get-WmiObject -class win32_computersystem -ComputerName $computer

                Write-verbose "Finished with WMI, building Output."
                if ($ShowProgress) { Write-Progress -Activity "Working on $Computer." -CurrentOperation "Creating Output." }
                $props = @{'ComputerName'="$computer";
                            'OSVersion'=$os.version;
                            'OSBuild'=$os.buildnumber;
                            'SPVersion'=$os.servicepackmajorversion;
                            'Model'=$cs.model;
                            'Manufacturer'=$cs.manufacturer;
                            'RAM'=$cs.totalphysicalmemory / 1gb -as [int];
                            'Sockets'=$cs.numberofprocessors;
                            'Cores'=$cs.numberoflogicalprocessors}
                $obj = New-Object -TypeName psobject -Property $props
                $obj.PsObject.Typenames.Insert(0,'PE.SystemInfo')

                Write-Verbose "Outputting to pipeline."
                Write-Output $obj

                Write-Verbose "Done with $computer."
            }
            if ($pipeline_mode) {
                $Current_complete = 100
            } else {
            $current_complete += $each_computer 
            }

            if ($ShowProgress) { Write-Progress -Activity "Working on $Computer." -PercentComplete $Current_Complete }
        }
    }
    END {
        if ($ShowProgress) { Write-Progress -Activity "Done" -Completed }
    }
}

'Nzxt' | Get-PESystemInfo -ShowProgress
#Get-PESystemInfo -ComputerName $computer -ShowProgress
#'Nzxt', 'LocalHost', 'LocalHost' | Get-PESystemInfo
#Import-CSV .\Computers.csv | Get-PESystemInfo
#Get-PESystemInfo -IPAddress 127.0.0.1, 127.0.0.1 -Verbose

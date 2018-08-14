 <#
 .SYNOPSIS
 Generates an HTML-based system report for one or more computers.
 Each computer specified will result in a separate HTML file;
 specify the -path as a folder where you want the files written.
 Note that existing files will be overwritten.
 .PARAMETER ComputerName
  One or more computer names or IP addresses to query.
 .PARAMETER Path
 The path of the folder where the files should be written.
 .PARAMETER CssPath
 The path and filename of the CSS template to use.
 .EXAMPLE
 New-HTMLSystemReport -Computername ONE,tWO `
                      -Path C:\Reports\
 #>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$True,
               ValueFromPipeline=$True,
               ValueFromPipelineByPropertyName=$True)]
    [String[]]$ComputerName,

    [Parameter(Mandatory=$True)]
    [String]$Path
)
PROCESS {

$Style = @"
<style>
Body {
    color:#333333;
    font-family:calibri,Tahoma;
    font-size: 10pt;
}
h1 {
    text-align:center;
}
h2 {
    border-top:1px solid #666666;
}

th {
    font-weight:bold;
    color:#eeeeee;
    background-color:#333333;
}
.odd { Background-color:#ffffff; }
.even { Background-color:#dddddd; }
</style> 
"@

function Get-InfoOS {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True)]
            [String]$Computername
        )
        $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computername
        $props = @{'OSVersion'=$os.Version;
                   'SPVersion'=$os.ServicePackageMajorVersion;
                   'OSBuild'=$os.BuildNumber}
        New-Object -TypeName PSObject -Property $props
}

function Get-InfoCompSystem {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$True)]
            [String]$ComputerName
        )
        $CS = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName
        $Props = @{'Model'=$CS.Model;
                   'Manufacturer'=$cs.Manufacturer;
                   'RAM (GB)'="{0:N2}" -f ($cs.totalphysicalmemory / 1GB);
                   'Sockets'=$cs.numberofprocessors;
                   'cores'=$cs.numberoflogicalprocessors}
        New-Object -TypeName PSObject -Property $props
}

function Get-InfoBadservice {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True)]
            [String]$ComputerName
        )
        $svcs = Get-WmiObject Win32_Service -ComputerName $ComputerName `
                -Filter "StartMode='Auto' AND State<>'Running'"
        foreach ($svc in $svcs) {
            $Props = @{'ServiceName'=$svc.name;
                       'LogonAccount'=$svc.startname;
                       'DisplayName'=$svc.displayname}
            New-Object -TypeName PSObject -Property $props
        }
}

function Get-InfoProc {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$True)]
            [String]$ComputerName
        )
        $procs = Get-WmiObject -class Win32_Process -ComputerName $ComputerName
        foreach ($proc in $Procs) {
            $props = @{'procname'=$Proc.Name;
                       'Executable'=$proc.ExecutablePath}
            New-Object -TypeName PSObject -Property $props
        }
}

function Get-InfoNIC {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$True)]
            [String]$ComputerName
        )
        $nics = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $ComputerName `
                -Filter "PhysicalAdapter=True"
        foreach ($nic in $nics) {
            $props = @{'NICName'=$nic.serviceName;
                       'Speed'=$nic.speed / 1MB -as [int];
                       'Manufacturer'=$nic.manufacturer;
                       'MACAddress'=$nic.macaddress}
            New-Object -TypeName PSObject -Property $props
        }
}

function set-AlternatingCSSClasses {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True,
            ValuefromPipeLine=$True)]
            [String]$HTMLFragment,

            [Parameter(Mandatory=$True)]
            [String]$CSSEvenClass,

            [Parameter(Mandatory=$True)]
            [String]$CssOddClass
        )
        [xml]$xml = $HTMLFragment
        $table = $xml.SelectSingleNode('table')
        $classname = $CssOddClass
        foreach ($tr in $table.tr) {
            if ($classname -eq $CSSEvenClass) {
                $classname = $CssOddClass
            } else { 
                $classname = $CSSEvenClass
            }
            $class = $xml.CreateAttribute('class')
            $class.value = $classname
            $tr.attributes.append($class) | Out-Null
        }
        $xml.InnerXml | Out-String
}

foreach ($computer in $ComputerName) {
    Try {
        $everything_ok = $true
        Write-Verbose "Checking Connectivity to $computer"
        Get-WmiObject -Class Win32_Bios -ComputerName $computer -EA Stop | Out-Null
    } catch {
        Write-Warning "$Computer failed"
        $everything_ok = $false
    }

    if ($everything_ok) {
        $filepath = Join-Path $path -ChildPath "$computer.html"

        $html_os = Get-InfoOS -Computername $Computer |
                   ConvertTo-Html -as List -Fragment `
                                  -PreContent "<h2>OS</h2>" |
                   Out-String

        $html_cs = Get-InfoCompSystem -ComputerName $Computer |
                   ConvertTo-Html -as List -Fragment `
                                  -PreContent "<h2>Hardware</h2>" |
                   Out-String
                   
        $html_pr = Get-InfoProc -ComputerName $Computer |
                   ConvertTo-Html -Fragment |
                   out-String |
                   set-AlternatingCSSClasses -CSSEvenClass 'even' -CssOddClass 'odd'
        $html_pr = "<h2>Processes</h2>$html_pr"

        $html_sv = Get-InfoBadservice -ComputerName $Computer |
                   ConvertTo-Html -Fragment |
                   Out-String | 
                   set-AlternatingCSSClasses -CSSEvenClass 'even' -CssOddClass 'odd'
        $html_sv = "<h2>Check services</h2>$html_sv"

        $html_na = Get-InfoNIC -ComputerName $computer |
                   ConvertTo-Html -Fragment |
                   Out-String | 
                   set-AlternatingCSSClasses -CSSEvenClass 'Even' -CssOddClass 'odd'
        $html_na = "<h2>NICs</h2>$html_na"
        $params = @{'Head'="<title>Report for $computer</title>$style";
                    'PreContent'="<h1>System Report for $computer</h1>";
                    'PostContent'=$html_os, $html_cs, $html_pr, $html_sv, $html_na}
        ConvertTo-Html @params | Out-File -filepath $filepath
    }
}
}

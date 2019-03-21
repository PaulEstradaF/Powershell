function Run-CitrixDelprof {
    [Cmdletbinding()]
    param (
    [parameter(mandatory=$True)]
    [ValidateSet('Group1','Group2','Group3')]
    [String[]]$DeliveryGroup
    )
    BEGIN {
        $CitrixHostsExcelLocation = '\\NetworkFolder\Powershell\Excel\CitrixHosts.xlsx'
        $CitrixHosts = Import-Excel -Path $CitrixHostsExcelLocation     
        $DeliveryGroupCount = $DeliveryGroup.Count
        If ($DeliveryGroupCount -eq 1) {
            $FilteredDeliveryGroup = $CitrixHosts | Where Group -Match $DeliveryGroup
        } elseif ($DeliveryGroupCount -eq 2) {
            $FilteredDeliveryGroup = $CitrixHosts | Where {$_.Group -Match $DeliveryGroup[0] -or $_.Group -match $DeliveryGroup[1]}
        } elseif ($DeliveryGroupCount -eq 3) {
            $FilteredDeliveryGroup = $CitrixHosts | Where {$_.Group -Match $DeliveryGroup[0] -or $_.Group -match $DeliveryGroup[1] -or $_.Group -match $DeliveryGroup[2]}
        } Else { Write-Host "Invalid Entry. Try running the command again." }
        Write-Output "You will be running Delprof2 on each of the following hosts." 
        Write-Output " "
        $FilteredDeliveryGroup.Hostname
        Write-Output " " 
        $Answer = Read-Host -Prompt "Would you like to continue? Yes or No"
       }      
     PROCESS {                
       if ($Answer -eq 'Yes') {
            Foreach ($Server in $FilteredDeliveryGroup) {
                $Args1 = "[Console]::Title='$($Server.Hostname)';[console]::WindowHeight='10';[Console]::WindowWidth='90';CLS"
                $Args2 = "\\NetworkFolder\scripts\DelProf2.exe /c:$($Server.IPAddress) /l;Pause"
                Start-Process Powershell -ArgumentList "$Args1;$Args2"
                }           
            } else {
            Write-Host "Ending Command."
            } 
        }
}

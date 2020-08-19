function Run-SM.CitrixProfileReset {
    [Cmdletbinding()]
    param (
    [parameter(Mandatory=$True)]
    [String[]]$TargetUsers
    )
    Begin { 
        $Verify_CitrixCommands = Try { Get-PSSession 'SMC-CitrixDLC01' } catch {
            Write-Host "Could Not Verify That Citrix Commands Have Been Imported." -ForegroundColor DarkRed
            Write-Host "Please try importing the Citrix commands again." -ForegroundColor DarkRed
            }
    }
    Process {
        Foreach ($TargetUser in $TargetUsers) {
            Write-Output ''
            Write-Host "[$TargetUser]"
            if ($Verify_CitrixCommands -ne $Null){
                $Servers = (Get-SM.CitrixUserConnectionLog $TargetUser -ErrorAction SilentlyContinue | Group Citrixhost | Select Name).Name      
                $Profiles = @{}
                $NoProfiles = @{}
                Foreach ($Server in $Servers) {
                    $Results = Test-Path \\$Server\c$\users\$TargetUser
                    if ($Results -eq $True) {
                        $Profiles.add("$Server","HasProfile")
                    } else {$NoProfiles.Add("$Server","NoProfile")}
                }
                if ($Profiles.Count -eq '0') {
                    $Time = Get-Date
                    Write-Host "[$($Time.ToLongTimeString())] $TargetUser does not have a local profile on any Citrix Host." -ForegroundColor DarkGray
                    } Else {
                    $Time = Get-Date
                    Write-Host "[$($Time.ToLongTimeString())] $Targetuser has $($Profiles.Count) profiles across our CitrixHosts." -ForegroundColor Yellow
                    Foreach ($Server in $Profiles.Keys) {
                        $Time = Get-Date
                        Write-Host "[$($Time.ToLongTimeString())] Removing Local Profile on $Server" -ForegroundColor Cyan
                        Start-Process Powershell -ArgumentList "
                            & '\\corp-archive1.sm.lan\SystemAdmins\PowerShell\Bat Files\DelProf2.exe' /C:$Server /id:$Targetuser /u
                            " -PassThru | Out-Null
                        } 
                    } 
            
                } Else {Write-host "[Could not verify that citrix commands were loaded.]" -ForegroundColor Yellow}
             }
        Write-Host ""
         }
}

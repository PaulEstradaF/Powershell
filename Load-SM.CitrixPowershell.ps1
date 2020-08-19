Function Load-SM.CitrixPowershell {
$DLC01 = New-PSSession -ComputerName SMC-CitrixDLC01 -Name 'SMC-CitrixDLC01' -Credential (Get-Credential)
Invoke-Command -Session $DLC01 -ScriptBlock {Import-Module Citrix*;Add-PSSnapin Citrix*}
Import-PSSession $DLC01 -DisableNameChecking -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null

#Displays the total number of imported commands from the session above.
(Invoke-Command -Session $DLC01 -ScriptBlock {Get-Command -Module Citrix* | Measure}).Count | 
    Select @{n="Total Number of Citrix Commands Loaded from $($DLC01.ComputerName)";e={$_}} | FL
}

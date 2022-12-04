function Add-O365License {
    [cmdletbinding()]
    param(
    	[Parameter(mandatory=$True,
        ValueFromPipeline=$True)]
	    $Identity,
        [switch]$Remove,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Group1","Group2","Group3","Group4")]
        [AllowNull()]
        [String]$License
        )

    $Account = Try { Get-ADUser -Identity $Identity -Properties * -ErrorAction SilentlyContinue } Catch {}
    $CurrentGroups = $Account | Select -ExpandProperty MemberOf | findstr Office365
    $CurrentADGroups = foreach ($group in $CurrentGroups) { Get-ADGroup -Identity $Group }
    
    if ($Remove -eq $True) {
        if ($CurrentGroups -eq $null) { Write-Host "$($Account.Name) is not in any Office365 AD Groups" 
            } Else { 
                Write-Host " Removing user from the following groups:"
                $CurrentGroups
                Foreach ($Group in $CurrentADGroups) {
                    Try { Remove-ADGroupMember -Identity $Group -Members $Identity -Confirm:$false 
                        } Catch { Write-Host "[Could not remove $($Account.Name) from the Office365 groups.]" }
                    }
                $CurrentGroups = $Account | Select -ExpandProperty MemberOf | findstr Office365
                $VerifyADGroupRemoval = foreach ($group in $CurrentGroups) {
                    Get-ADGroup -Identity $group | Out-Null }
                if ($VerifyADGroupRemoval -eq $null) {
                    Write-Host "Successfully removed $($Account.Name) from all Office365 Groups." -ForegroundColor Green                                    
                    }
                }
        } Else {    
            if ($Account -eq $null) {
                Write-Host ""
                Write-Host "There is no account for the ID $identity. Verify you entered the correct ID." -ForegroundColor Red
                } Else { Write-Host "Checking if $($Account.Name) is in any Office365 AD group." }
                if ($CurrentGroups -eq $null) {
                    if ($License -notlike "*office*") {
                       Write-Host ""; Write-Host "No license specified. Please try running the command again."
                            } Else {
                                Write-Host "- $($Account.Name) is currently not a member of any Office365 AD Group."
                                $Answer = Read-Host " Would you like to like to add them to $License`?"
                                If ($Answer -eq 'Yes' -or $Answer -eq 'Y') { 
                                    Try {
                                        Add-ADGroupMember -Identity $License -Members $Identity 
                                        } catch { 
                                            Write-Host ""; Write-Host "Could not add $license to $Identity. Try running the command again." -ForegroundColor Red
                                            }
                                    } else { 
                                        Write-Host "";Write-Host " Okay."
                                        }
                                } 
                    } Else {
                        Write-Host "- $($Account.Name), $Identity, belongs to $($CurrentGroups.count) AD Groups." -ForegroundColor Yellow
                        Write-Host " "
                        $CurrentADGroups.Name
                        }
            } 
}

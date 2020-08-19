Function Add-SM.O365MailboxAccess {
<#
.SYNOPSIS
	Adds delegated access to an Office365 Mailbox.
.DESCRIPTION
	This command allows you to grant any user(s) access to any mailbox(s). You can specify whether you want to grant full access or send as access. 
.EXAMPLE
	Add-SM.O365MailboxAccess -ToMailboxes mailbox1@domain.com -ForEmployeeIds 001,002,003,004 -AccessRights SendAs,FullAccess
	
#>

    [cmdletbinding()]
    Param (
        [Parameter()]$ToMailboxes,
        [Parameter()]$ForEmployeeIDs,
        [ValidateSet('SendAs','FullAccess')]
        [Parameter()]$AccessRights
    )
    Foreach ($Mailbox in $ToMailboxes) {
        Foreach ($User in $ForEmployeeIDs) {
        $UserADInfo = Get-Aduser -Identity $User | Select * 
            if ($AccessRights.Count -le 1) {        
                if ($AccessRights -eq 'SendAs') {
                    Add-RecipientPermission -Identity $Mailbox -AccessRights SendAs -Trustee $user -Confirm:$False -WarningAction SilentlyContinue | Out-Null
                    Write-Host "Added SendAs permission to $Mailbox for $($UserADInfo.Name), $user" -ForegroundColor 'Green'
                    } Elseif ($AccessRights -eq 'FullAccess') {
                        Add-MailboxPermission -Identity $Mailbox -AccessRights $AccessRights -User $User -WarningAction SilentlyContinue | Out-Null
                        Write-Host "Added FullAccess permission to $Mailbox for $($UserADInfo.Name), $user" -ForegroundColor 'Green'
                        } Else {Write-Host "Verify you entered information properly." -ForegroundColor DarkRed}
                } Else {
                    #AddsSendAs
                    Try {
                        Add-RecipientPermission -Identity $Mailbox -AccessRights SendAs -Trustee $user -Confirm:$False -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                        } Catch {Write-Host "Verify that the information you entered is correct." -ForegroundColor DarkRed}
                    Write-Host "Added SendAs permission to $Mailbox for $($UserADInfo.Name), $user" -ForegroundColor 'Green'

                    #AddsFullAccess
                    Try { 
                        Add-Mailboxpermission -Identity $Mailbox -AccessRights FullAccess -User $User -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
                        } Catch {Write-Host "Verify that the information you entered is correct." -ForegroundColor DarkRed}
                    Write-Host "Added FullAccess permission to $Mailbox for $($UserADInfo.Name), $user" -ForegroundColor 'Green'
            }
        }
    }
}

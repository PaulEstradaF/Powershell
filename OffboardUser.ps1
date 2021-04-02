 #This Script Offboards users. It will prompt for credentials, sign you into the necessary services, then prompt for the employee to offboards UserID and perform the following:
#(Additional services can be signed into on M365 but are commented out for lack of necessity for this script)
#1: Block Cloud Sign on
#2: Sign out all sessions
#3: Disable On-Premise AD Account
#4: Update description with "Offboarded %DATE% By: %USERID%"
#5: Change  "msExchHideFromAddressLists" to true
#6: Clear Reports to attribute
#7: Clears Reports to Attribute of all direct reports
#8: Copies results to clipboard to be pasted into ticket. 

$orgName="savemartsupermarkets"
$credential = Get-Credential -Message "Office365 Signin"
#Azure Active Directory
Connect-MsolService -Credential $credential
#SharePoint Online
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -credential $credential
#Skype for Business Online
#Import-Module MicrosoftTeams
#Connect-MicrosoftTeams -Credential $credential
#Exchange Online
#Import-Module ExchangeOnlineManagement
#Connect-ExchangeOnline -Credential $credential -ShowProgress $true
#Security & Compliance Center
#Connect-IPPSSession -Credential $credential
#Teams
#Import-Module MicrosoftTeams
#Connect-MicrosoftTeams -Credential $credential

#Get admin inf 
$admin = (whoami).trim("sm\")
$date = date -Format d

#Get User-Id to Off-board
$EmpNumber = Read-Host -Prompt 'What is the users Employee #?'

#Load Employee Ino
$User = get-aduser -identity $EmpNumber -Properties *

#Signout Sharepoint and OneDrive Sessions
Revoke-SPOUserSession -User $User.UserPrincipalName

#Block AzureAD Login
Set-AzureADUser -ObjectId $User.UserPrincipalName -AccountEnabled $False

#Disable On-Premise AD Account
Disable-ADAccount -Identity $EmpNumber

#Append Description
get-aduser $EmpNumber -Properties Description | ForEach-Object { Set-ADUser $_ -Description "$($_.Description) --Offboarded on $date by $admin" }

#Move User to Offboard OU
Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=Offboard,OU=-SaveMart-,DC=SM,DC=LAN"

#Hide User from Addresslist
Set-ADUser -Identity $EmpNumber -Replace @{msExchHideFromAddressLists=$True}

#Get User Manager, clear manager, set direct reports new manager to managers previous manager to prevent unmanaged people.
$manager = get-aduser $empnumber -Properties * | select manager
$managerSAM = get-aduser -Identity $manager.manager -Properties SamAccountName | select SamAccountname
$directreports = get-aduser $empnumber -Properties * | select -expand directreports
foreach ($dr in $directreports) {
    $dr1 = get-aduser $dr |select SamAccountName 
    set-aduser -Identity $dr1.SamAccountName -Manager $managersam.SamAccountname
    }
set-aduser -Identity $empnumber -Manager $null
Write-Output 'User has been blocked from sign ons in the cloud, signed out of M365 sessions, disabled in on-premise AD, hidden from address book, description updated, moved to offboarded OU, manager cleared, and all direct reports have had their manager changed to their managers manager.' | set-clipboard
Write-Output "Script Completed, Results Copied to Clipboard, please paste in notes of ticket." 

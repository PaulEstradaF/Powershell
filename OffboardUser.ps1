 #This Script Offboards users. It will prompt for credentials, sign you into the necessary services, then prompt for the employee to offboards UserID and perform the following:
#(Additional services can be signed into on M365 but are commented out for lack of necessity for this script)
#1: Block Cloud Sign on
#2: Sign out all sessions
#3: Sign out of WVD
#4: Sets an automatic response with the managers name and email address
#5: Sets an automatic forward to the managers account. 
#6: Sets the manager as an owner on the users onedrive
#7: Disable On-Premise AD Account
#8: Update description with "Offboarded %DATE% By: %USERID%"
#9: Change  "msExchHideFromAddressLists" to true
#10: Clear Reports to attribute
#11: Clears Reports to Attribute of all direct reports
#12: Send email to users manager with informing off the offboard as well as including link to users ondrive files. 
#13: Copies results to clipboard to be pasted into ticket. 

$orgName="ORGNAME"
$credential = Get-Credential -Message "Office365 Signin"

#SMTP Server
$PSEmailServer = SMTP SERVER

#Azure Active Directory
Connect-AzureAD -Credential $Credential
Connect-MsolService -Credential $credential

#SharePoint Online
Import-Module Microsoft.Online.SharePoint.PowerShell -DisableNameChecking
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -credential $credential

#Skype for Business Online
#Import-Module MicrosoftTeams
#Connect-MicrosoftTeams -Credential $credential
#Exchange Online

#Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -Credential $credential -ShowProgress $true

#Security & Compliance Center
#Connect-IPPSSession -Credential $credential
#Teams
#Import-Module MicrosoftTeams
#Connect-MicrosoftTeams -Credential $credential

#Connect to WVD Environment
add-rdsaccount -Credential $credential -DeploymentUrl https://rdbroker.wvd.microsoft.com
$my = [PSCustomObject]@{
 
    # Shouldn't need to change these
    AzureSubscriptionID = "****";
    AADTenantID    = "****";
    # Don't change these default names or it'll break stuff
    TenantGroupName     = "Default Tenant Group";
    AppGroupName        = "Desktop Application Group";
    # Update these as needed
    TenantCreator       = "***"
    TenantName          = "***";
    HostPoolName        = "***";
    TenantFriendlyName  = "***";
    AppGroupFriendlyName= "Desktop Session"; } 
 

#Get admin information
$admin = (whoami).trim("sm\")
$adminBaseUPN = ($admin).trim("adm")
$adminbase = get-aduser -identity $adminBaseUPN -Properties *
$date = date -Format f


#Get User-Id to Off-board
$EmpNumber = Read-Host -Prompt 'What is the users Employee #?'

#Load Employee Info
$User = get-aduser -identity $EmpNumber -Properties *
$name = $user.Name
$email = $user.mail
$UserUPN = $user.UserPrincipalName
$UserSAM = $user.SamAccountName
$manager = get-aduser $user.manager -Properties *
$ManagerName = $manager.Name
$manageremail = $manager.mail
$ODurl = "https://ORGINFO/personal/${UserSAM}_savemart_com"

#Set Email Auto-Forward
#Set-mailbox $email -ForwardingAddress $manageremail
#Set-mailbox $email -ForwardingAddress $null

#Set Automatic Reply
#Set-MailboxAutoReplyConfiguration -Identity $user.SamAccountName -AutoReplyState Enabled -InternalMessage "Thank you for reaching out.  I am no longer with The Save Mart Companies. For assistance, please contact $ManagerName at $manageremail." -ExternalAudience All -ExternalMessage "Thank you for reaching out.  I am no longer with The Save Mart Companies. For assistance, please contact $ManagerName at $manageremail."

#Add Manager as OneDrive Secondary Owner
Set-SPOUser -Site $ODurl -LoginName $Manager.UserPrincipalName -IsSiteCollectionAdmin $True -ErrorAction SilentlyContinue
#Get-SPOUser -site $ODurl | Select LoginName,IsSiteAdmin | Where-Object {$_.IsSiteAdmin -eq 'True'}

#Signout Sharepoint and OneDrive Sessions
Revoke-SPOUserSession -User $User.UserPrincipalName -Confirm:$false

#Sign out of any WVD Sessions:
Get-RdsUserSession -TenantName "***" -HostPoolName "***" | Where-Object UserPrincipalName -eq "$UserUPN"# | Invoke-RdsUserSessionLogoff


#Block AzureAD Login
Set-AzureADUser -ObjectId $User.UserPrincipalName -AccountEnabled $False

#Disable On-Premise AD Account
Disable-ADAccount -Identity $EmpNumber

#Append Description
get-aduser $EmpNumber -Properties Description | ForEach-Object { Set-ADUser $_ -Description "$($_.Description) --Offboarded on $date by $admin" }

#Move User to Offboard OU
Move-ADObject -Identity $user.DistinguishedName -TargetPath "OU=OU-FOR-OFFBOARDED-ACCOUNTS"

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

#Email Variables
$Subject = "Offboard of $name"
$from = "ADDRESS"

#MessageBody
$MessageBody = @"
$managername,
$name has been offboarded effective $date. As part of this process you have been granted owner access to the users OneDrive Account. 
You may access that via this link: $ODUrl 

We have also included an autoforward of all email sent to $email to your email address and an auto-reponse stating:
Thank you for reaching out.  I am no longer with The Save Mart Companies. For assistance, please contact $ManagerName at $manageremail

If you have any questions please feel free to reach out to the HelpDesk.

Thank You,
Platform Engineering
"@

Send-MailMessage -From $from -To $manageremail -Subject $Subject -Body $MessageBody -SmtpServer $PSEmailServer -Credential $credential
write-output "$Name has been blocked from sign ons in the cloud, signed out of M365 sessions, disabled in on-premise AD, hidden from address book, an automatic email response has been generated instructing to send all mail to $ManagerName at $manageremail, an autoforward of all email $ManagerName has been created, the manager has been set as an additional owner on the onedrive files, an email has been sent to the manager informing them of the auto-reply, the auto-forward, onedrive ownership, and including a link to the onedrive files, the description updated, moved to offboarded OU, manager cleared, and all direct reports have had their manager changed to their managers manager." | set-clipboard
Write-Output "Script Completed, Results Copied to Clipboard, please paste in notes of ticket." 

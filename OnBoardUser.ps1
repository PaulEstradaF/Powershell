 Function Load-SM.ExchangeCommands {
    $onPremExchange = New-PSSession -Name onPremExchange -ConfigurationName Microsoft.Exchange `
                                    -ConnectionUri http://ExchangeManage.SM.LAN/PowerShell -Authentication Kerberos -WarningAction SilentlyContinue `
                                    -Credential (Get-Credential)
    Import-PSSession $onPremExchange -AllowClobber -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
    Out-Null
}; Load-SM.ExchangeCommands

#License Choice and Username variables
Write-Host "Please choose a license for the user:"
write-host "1: Office365 F3 (Generally used for Store accounts i.e. Gen, SBC, & RX)"
write-host "2: Office365 E3 (Generally used for Corporate Employees, named accounts, and MGR accounts)"
write-host "3: Office365 E3+AudioConference (Same as E3 License but adds Teams Audio Conference License)"

$OfficeLicense = Read-Host -Prompt 'License'
$EmpNumber = Read-Host -Prompt 'What is the users Employee #?'

#Create License Varible from choice
if($OfficeLicense -eq 1){
   $LicenseName = "Office365-F3"
} elseif($OfficeLicense -eq 2){
  $LicenseName = "Office365-E3"
}elseif($OfficeLicense -eq 3){
  $LicenseName = "Office365-E3+AudioConference"
}else {
   write-host("No license selected/being applied")
}

#Gather User information
$user = Get-aduser $EmpNumber -Properties *
$firstname = $user.givenname 
$lastname = $user.surname
$mgrname = (get-aduser $user.manager |Select distinguishedname).Distinguishedname.split('=')[1]
$mgrclean = $mgrname.Split(',')[0]
$MgrOU = (get-aduser $user.manager |Select distinguishedname).Distinguishedname.split(',',2)[1]
$userGUID = Get-ADObject -Identity $user -Properties * | select ObjectGUID
$OUGUID = Get-ADObject -Identity $mgrou -Properties * | select ObjectGUID

#Email Account Variables
$email = "$EmpNumber@savemart.com"
$AltEmail = "$EmpNumber@savemartsupermarkets.mail.onmicrosoft.com"

#Creation Of Mailboxes
Enable-RemoteMailbox $email -RemoteRoutingAddress $AltEmail
Enable-RemoteMailbox $email -Archive
Set-RemoteMailbox $Email

#Add License
Add-ADGroupMember -Identity $LicenseName -members $EmpNumber

#Move AD Object to Managers OU
Move-ADObject -Identity $user -TargetPath $mgrou

#Expected Results
echo $firstname
echo $lastname
echo $email
echo $Altemail
echo $LicenseName Applied to $User.name
echo User moved to $MgrOU
write-output "$Firstname $Lastname has had a mailbox created, an online archive created, and an office365 license applied ($Licensename) and moved to the OU $mgrOU to match their manager $MgrClean" | set-clipboard 

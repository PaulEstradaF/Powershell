 #License Choice and Username variables
Write-Host "Please choose a license for the user:"
write-host "1: Office365 E1 (Generally used for Store accounts i.e. Gen, SBC, & RX)"
write-host "2: Office365 E3 (Generally used for Corporate Employees, named accounts, and MGR accounts)"
$OfficeLicense = Read-Host -Prompt 'License'
$EmpNumber = Read-Host -Prompt 'What is the users Employee #?'

#Create License Varible from choice
if($OfficeLicense -eq 1){
   $LicenseName = "Office365-F1"
} elseif($OfficeLicense -eq 2){
  $LicenseName = "Office365-E3"
}else {
   write-host("No license selected/being applied")
}

#Gather User information
$user=Get-aduser $EmpNumber
$firstname = $user.givenname 
$lastname = $user.surname

#Email Account Variables
$email = "$EmpNumber@REPLACEWITHDOMAIN"
$AltEmail = "$EmpNumber@REPLACEWITHPROPERDOMAIN.mail.onmicrosoft.com"

#Creation Of Mailboxes
Enable-RemoteMailbox $email -RemoteRoutingAddress $AltEmail
Enable-RemoteMailbox $email -Archive
Set-RemoteMailbox $Email

#Add License
Add-ADGroupMember -Identity $LicenseName -members $EmpNumber

#Expected Results
echo $firstname
echo $lastname
echo $email
echo $Altemail
echo $LicenseName 

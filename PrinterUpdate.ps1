[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
#$UserCreds = Get-Credential
Set-ExecutionPolicy RemoteSigned
$session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://Corp-EXCas1.SM.LAN/PowerShell -Authentication Kerberos #-Credential $UserCreds
Import-PSSession $session -AllowClobber -DisableNameChecking
#IP to find
Add-Type -AssemblyName Microsoft.VisualBasic
$Printer = [Microsoft.VisualBasic.Interaction]::InputBox('Enter the IP of the printer to update', 'Printer')

$CurrentConnector = Get-ReceiveConnector -Server Corp-ExCas1 | Where RemoteIPRanges -like "$printer" | Select-object *
$fullname = $CurrentConnector."name"


#Connector you want to add to
$NewConnetor = Get-ReceiveConnector -Server Corp-ExCas1 | Where Name -like "*Auth*" | Select-object *
$NewAUthConnector = $NewConnetor."name"

# Get Receive Connectors to update
$recCons= Get-ReceiveConnector | where {$_.name -like "$fullname"}
ForEach ($recCon in $recCons)
{
      Write-Host "Updating" $fullname
       $index = $CurrentConnector.RemoteIPRanges.IndexOf($printer)
       $reccon.RemoteIPRanges.Remove($recCon.RemoteIPRanges[$index])
       Set-ReceiveConnector "$recCon" -RemoteIPRanges $recCon.RemoteIPRanges
}

$NewrecCons= Get-ReceiveConnector | where {$_.name -like "$NewAuthConnector"}
ForEach ($NewrecCon in $NewrecCons)
{
      Write-Host "Updating" $NewAUthConnector
       $NewrecCon.RemoteIPRanges.Add($printer)
       Set-ReceiveConnector "$NewrecCon" -RemoteIPRanges $NewrecCon.RemoteIPRanges
}
Write-Host "Removed $ip from: $FullName"
Write-Host "Added $ip to: $NewAuthConnector"
[Microsoft.VisualBasic.Interaction]::MsgBox("A new config file for:`n$newprinter`nHas been saved to `n$env:USERPROFILE\Desktop\Settings.ucf`n`nRemoved: $ip`nFrom: $Fullname`n`nAdded: $ip`nTo: $NewAuthConnector`n`nThe Following Scanner cahnges will be made:`nReply Address: NoReply@Savemart.com`nSMTP Address (Changed to DNS)`nSMTP Username`nSMTP Password`nDNS Server (added sm.lan)`nSMTP Auth Requirement`nSMTP TLS Requirement`nKerberose Realm Set`nEmail SendMeCopy Disabled`nEmail Subject Includes Printer $newprinter`n`nLaunching Browser for:`n$newprinter`n`nPlease Upload the new config file per instructions.", "OKOnly,SystemModal,Information", "Success")
$AllPrinters =@()
$Printservers = Get-ADObject -LDAPFilter "(&(&(&(uncName=*)(objectCategory=printQueue))))" -properties *|Sort-Object -Unique -Property servername | where Servername -notlike "ROSETRAN071071D.SM.LAN" | where Servername -notlike "Vac-File1.SM.LAN" | select ServerName
#$Printservers = "Annex-Print1.sm.lan"
Foreach ($server in $Printservers.servername)
{
   $printers = Get-Printer -Computername $server -ErrorAction SilentlyContinue
   $Allprinters += $Printers
}
    
$newprinter = ($AllPrinters | where portname -like $printer | sort-object -Unique -Property Name).name

$string1 = @"
mfp.ldap.serverAddress "10.101.6.7"
mfp.ldap.serverPort "389"
mfp.ldap.searchBase "dc=sm,dc=lan"
mfp.ldap.userIdAttribute "cn"
mfp.ldap.searchTimeout "30"
mfp.ldap.maxSearchResults "100"
mfp.email.primarySMTPServer "smtp.sm.lan"
mfp.email.primarySMTPPort "25"
mfp.email.smtpTimeout "30"
mfp.email.attachmentType "0"
mfp.email.smtp.username "SMTP-MFP"
mfp.email.smtp.password "#YUZ%u5V9arF"
mfp.email.smtp.authenticationRequired "4"
mfp.email.replyAddress "NoReply@SaveMart.com"
network.dns.serverAddress "0x0A650106"
network.ip.DNSserverAddress2 "0x0a6506be"
mfp.ldap.SSL_TLS "0"
mfp.ldap.GSSAPI "false"
mfp.ldap.displayedName "0"
mfp.ldap.mail "mail"
mfp.networkScan.sendMeCopy "0"
mfp.networkScan.maxEmailSize "0"
mfp.networkScan.emailSizeErrorMsg ""
mfp.ldap.tls_reqcert "3"
mfp.email.useSystemCredentials "1"
mfp.email.smtp.credentialsPrompts "1"
mfp.email.smtp.protocolSecurity "2"
mfp.email.smtp.ntlmDomain "SM.LAN"
mfp.email.smtp.kerberos5Realm ""
mfp.email.validateCA "false"
network.lexlink.enabled "false"
network.ip.TTL "254"
mfp.email.subject "Scanned Document From $newprinter"
"@
Remove-Item -Path "$env:USERPROFILE\Desktop\Settings.ucf" -ErrorAction SilentlyContinue
Set-content -Path "$env:USERPROFILE\Desktop\Settings.ucf" -Value $String1
Start "http://$printer"
Remove-PSSession *
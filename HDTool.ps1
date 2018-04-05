<#
	Script Name: HDTool.ps1
	Description: This is a living tool that will be updated periodically. It has access to all of the tools we use at the help desk for troubleshooting.
	It also consolidates information we would normally retrieve from several different sources.
	Author: Paul Estrada
	Last Update: 4/4/2018
	
#>
function Show-Menu
{
    param (
        [string]$Title = 'Help Desk Tool'
    )
    cls
    Write-Host " ______________________________________________________________________________ "
    Write-Host "                              [ $Title ]"
    Write-Host " ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ "
    Write-Host "                                                                                "

    Write-Host "1.) Domain1 Account Information."
    Write-Host "2.) Domain2 Account Information."
    Write-Host "3.) Register System Logs."
    Write-Host "4.) Fast Lane System Logs."
    Write-Host "5.) Reboot Log for Register/Fast Lane. *Domain1 Only*"
    Write-Host "6.) Fast Lane Diagnostic Files."
    Write-Host "7.) Fast Lane Diagnostic Files. *Domain1 Only*" 
    Write-Host "HH.) Shadow An Ordering Hand Held Gun"
    Write-Host "D.) Corporate Phone Directory"
    Write-Host "SI.) Store Information"
    Write-Host " "
    Write-Host "Press 'Q' to quit."
    Write-Host " "
}

do
 {
  show-menu
     $selection = Read-Host "Please make a selection"
     switch ($selection)
     {
#Option 1 - This retrieves Active Directory information for our Domain1 Domain
         '1' {
             cls
$user = Read-Host -Prompt 'What is the Login Name?'
get-aduser -identity $user -properties CanonicalName, department, title, PasswordExpired, LockedOut, PasswordLastSet, BadLogonCount, LastBadPasswordAttempt,  Office, ipPhone, OfficePhone, MobilePhone, MemberOf |
Select-Object -Property "Name", "Department", "Title", "CanonicalName", "PasswordExpired", "LockedOut", "PasswordLastSet", "BadLogonCount", "LastBadPasswordAttempt",  "Office", "OfficePhone", "ipPhone", "MobilePhone", "MemberOf"
         } 

#Option 2 - This retrieves Active Directory information for our Domain2 Domain
         '2' {
             cls
$user = Read-Host -Prompt 'What is the Login Name?'
Get-ADUser -identity $user -server Domain2.CompanyName.com -properties CanonicalName, department, title, PasswordExpired, LockedOut, PasswordLastSet, BadLogonCount, LastBadPasswordAttempt,  Office, ipPhone, OfficePhone, MobilePhone, MemberOf |
Select-Object -Property "Name", "Department", "Title", "CanonicalName", "PasswordExpired", "LockedOut", "PasswordLastSet", "BadLogonCount", "LastBadPasswordAttempt",  "Office", "OfficePhone", "ipPhone", "MobilePhone", "MemberOf"
         } 

#Option 3 - This copies the system log from the specified register or fast lane and places it in a folder named Registers on your POS Desktop
         '3' {
             cls
Write-Host "This will create a folder titled Registers on your POS desktop "
Write-Host "with the system log for the specified register or fast lane."
Write-Host " "
$Domain2Username = Read-Host -Prompt 'What is your Domain2 username?'
$StoreNumber = Read-Host -Prompt 'What is the 3 digit store number?'
$RegisterNumber = Read-Host -Prompt 'What is the 2 digit register number?'
$passwd = Read-Host -Prompt "What is the register's password?"
$hostname = "\\Store0" + $StoreNumber + "POS0" + $RegisterNumber
$DestinationFile = "c:\documents and settings\"+$Domain2Username+"\desktop\registers\Store0"+$storenumber+"pos0"+$registernumber+"system.evtx"
$DestinationFile2 = "c:\documents and settings\"+$Domain2Username+"\desktop\registers\Store0"+$storenumber+"pos0"+$registernumber+"Application.evtx"
$folderpath = "c:\documents and settings\"+$Domain2Username+"\desktop\Registers"
$register = "store0"+$storenumber+"pos0"+$registernumber+"\Domain1"
$fastlane = "store0"+$storenumber+"pos0"+$registernumber+"\FLUsername"
$hostnamemap = "\\Store0" + $StoreNumber + "POS0" + $RegisterNumber + "\c$"
$PathFile = $hostnamemap + "\windows\system32\winevt\logs\system.evtx"
$PathFile2 = $hostnamemap + "\windows\system32\winevt\logs\Application.evtx"
net use $hostnamemap $passwd  /persistent:yes /user:$register
New-Item -ItemType directory -path $folderpath
Copy-Item -path $PathFile -destination $DestinationFile
Copy-Item -Path $PathFile2 -Destination $DestinationFile2
net use $hostnamemap /delete
pause
         }

##Viewlogs - This can only be run from your desktop. This maps a drive to the location of the system and application event logs in the POS Server then launches a tool that can open up the logs.
        'viewlogs' {
$Domain2username = Read-Host -Prompt "What is your Domain2 username?"
$Domain2password = Read-host -Prompt "What is your Domain2 password?"
write-host = Examples: sm0105p, fm0420p, sm0707p
$POSServer = Read-Host -Prompt "What is the store server name?"
$LogFolder = "P:\Documents and settings\"+ $Domain2username +"\desktop\registers"
Net use P: \\$POSServer\c$ $Domain2password /persistent:yes /user:Domain2\$Domain2username
& "C:\HDTool\Applications\FullEventLogView.exe" /datasource 3 /logfolder $logfolder
            }

#Option 4 - This copies the System Log from the specified register or fast lane and places it in a folder named Registers on your POS Desktop
         '4' {
             cls
Write-Host "This will create a folder titled Register on your POS desktop "
Write-Host "with the system log for the specified register or fast lane."
Write-Host " "
$StoreNumber = Read-Host -Prompt 'What is the 3 digit store number?'
$RegisterNumber = Read-Host -Prompt 'What is the 2 digit fast lane number?'
$passwd = Read-Host -Prompt "What is the Fast Lane's password?"
$hostname = "\\Store0" + $StoreNumber + "POS0" + $RegisterNumber
$DestinationFile = "c:\documents and settings\Domain2Username\desktop\registers\Store0"+$storenumber+"pos0"+$registernumber+"system.evtx"
$folderpath = "c:\documents and settings\Domain2Username\desktop\Registers"
$fastlane = "store0"+$storenumber+"pos0"+$registernumber+"\FLUsername"
$hostnamemap = "\\Store0" + $StoreNumber + "POS0" + $RegisterNumber + "\c$"
$PathFile = $hostnamemap + "\windows\system32\winevt\logs\system.evtx"
net use $hostnamemap $passwd  /persistent:yes /user:$fastlane
New-Item -ItemType directory -path $folderpath
Copy-Item -path $PathFile -destination $DestinationFile
net use $hostnamemap /delete
         }

#Option 5 - Reboot Log for Fast Lanes or Registers. This only works for Domain17 Stores. 
#This can be modified to show whatever EventID we would like or to be anything for the current date.
         '5' {
             cls
             $StoreNumber = Read-Host -Prompt 'What is the 3 digit store number?'
$RegisterNumber = Read-Host -Prompt 'What is the 2 digit register number?'
$hostname = "Store0" + $StoreNumber + "POS0" + $RegisterNumber
Get-WinEvent -FilterHashtable @{logname='System'; id=6005, 6006} -computername $hostname -credential $hostname"\Domain1" | Where-Object {$_.timecreated -gt ((get-date).adddays(-30))}
pause
        }

#Option 6 - FLUsername Diagnostic Files
#This gets all of the Traces, TBTraces, Domain1IOClient_salesw2k, Domain1IOClient_FLUsernameAppU, and Domain1HookManager log files from the current date and places them onto a folder on your POS Desktop
        '6' {
             cls
#This gets the variable information for the fast lane.
$Ipaddress = Read-Host -Prompt "What is the IP address of the Fast Lane?" 
$StoreNumber = Read-Host -Prompt "What is the 3 digit Store number?"
$LaneNumber = Read-Host -Prompt "What is the 2 digit Lane number?"
$hostname = "Store0" + $StoreNumber + "POS0" + $LaneNumber
$Domain2username = Read-Host -Prompt "What is your Domain2 username?"

#This mounts  the the hard drive of the fast lane to M: in the POS server.
net use m: \\$Ipaddress\c$ FLUsername /persistent:yes /user:$Ipaddress\FLUsername

#This sets the folders that will be searched for the log files.
$sourceList = "\\$ipaddress\c$\FLUsername\logs", "\\$ipaddress\c$\FLUsername\bin", "\\$ipaddress\c$\Domain1\Data", "\\$ipaddress\c$\Domain1"

#This sets the destination for the log files that are being copied
$destination = "c:\Documents and Settings\$Domain2username\desktop\$hostname"

#This makes a new folder on your POS desktop where the files will be copied
New-Item -ItemType Directory -Path "c:\Documents and Settings\$Domain2username\desktop\$hostname"

#This copies the log files onto the folder that was created above
Get-ChildItem -Path $sourceList -filter "Name1.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Name2.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Name3.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Name4.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Name5*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse

#This unmounts the M drive
net use M: /delete
            }

#Option 7 - FLUsername Diagnostic Files - 
#This gets all of the Name1, Name2, Name3, Name4, Name5 log files from the current date and places them onto a folder on your POS Desktop
        '7' {
             cls
#This gets the variable information for the fast lane.
$Ipaddress = Read-Host -Prompt "What is the IP address of the Fast Lane?" 
$StoreNumber = Read-Host -Prompt "What is the 3 digit Store number?"
$LaneNumber = Read-Host -Prompt "What is the 2 digit Lane number?"
$hostname = "Store0" + $StoreNumber + "POS0" + $LaneNumber
$Domain1Username = Read-Host -Prompt "What is your FLUsername username?"

#This mounts  the the hard drive of the fast lane to M: in the POS server.
net use m: \\$Ipaddress\c$ FLUsername /persistent:yes /user:$Ipaddress\FLUsername

#This sets the folders that will be searched for the log files.
$sourceList = "\\$ipaddress\c$\FLUsername\logs", "\\$ipaddress\c$\FLUsername\bin", "\\$ipaddress\c$\Domain1\Data", "\\$ipaddress\c$\Domain1"

#This sets the destination for the log files that are being copied
$destination = "c:\users\$Domain1Username\desktop\$hostname"

#This makes a new folder on your POS desktop where the files will be copied
New-Item -ItemType Directory -Path "c:\users\$Domain1Username\desktop\$hostname"

#This copies the log files onto the folder that was created above
Get-ChildItem -Path $sourceList -filter "Log1.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Log3.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Log3.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Log4.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse
Get-ChildItem -Path $sourceList -filter "*Log5.log*" | Where-Object {$_.LastWriteTime -ge [datetime]::Today} | Copy-Item -Destination $destination -Recurse

#This unmounts the M drive
net use M: /delete
        }

#Option HH - Hand Held Shadowing Tool
#This looks at Y:\HD\App\WLRemoteControl MC 4.082 for WLRemoteControl.exe
        'HH' {
cls
Write-Host "How to get IP address:"
Write-Host "From the Avalanche screen click on Help then Adapater Info."
Write-Host " "
$HHIP = Read-host -Prompt "What is the Hand Held's IP Address?"
cd 'Y:\HD\App\WLRemoteControl MC 4.082'
.\WLRemoteControl.exe /action:view /connect:tcpip /device:$HHIP
cd c:\
            }

#SI - This uses an XML file, Y:\HD\App\PS HD Tool\StoreInfo.xml. The information needs to be edited manually.
         'SI' {
cls
Write-Host "                                                                                "
Write-Host " ______________________________________________________________________________ "
Write-Host "                            [ Store Information ]"
Write-Host " ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ "
Write-Host "                                                                                "
Write-Host "Enter the store's 3 digit number to find information about the store."
Write-Host "                                                                                "
$storenumber = Read-Host -Prompt "What is the 3 digit store number?"
Write-Host "                                                                                "
[xml]$xml = get-content -path "C:\HDTool\Xml\Storeinfo.xml"
$xml.store_information.storeinfo | Where-Object -Property storenumber -eq $storenumber
            }
            
#Directory - Launches the corporate directory url using your default computer browser
        'D' {
Start-Process -FilePath http://svdirsvc.intranet.CompanyName.com
            }
			
#Slack - Launches the company's Slack url using your default computer browser
        'Slack' {
Start-Process -FilePath https://it-CompanyName.slack.com/messages
            } 
			
#Nagios - Launches the Nagios url using your default computer browser
        'Nagios' {
Start-Process -FilePath http://nagios.intranet.CompanyName.com/check_mk/index.py?start_url=%2Fcheck_mk%2Fview.py%3Fview_name%3Dsvcproblems           
            }

#Print Management - This launches a "C:\HDTool\Applications\Print Management.msc"
         'PM' {
Start-Process -FilePath "C:\HDTool\Applications\Print Management.msc"
            }

#Smart 401 - This launches "C:\HDTool\Applications\Smart401.ws"
        'S401' {
Start-Process -FilePath "C:\HDTool\Applications\Smart401.ws"
            }
			
#Smart 402 - This launches "C:\HDTool\Applications\Smart401.ws"
        'S402' {
Start-Process -FilePath "C:\HDTool\Applications\Smart402.ws"
            }

#RASupport - This launches the Company Name Remote Assistance Tool
#This tool us used for shadowing corporate users. The location of the file is: "C:\HDTool\Applications\RASupport.exe"
        'RS' {
Start-Process -FilePath "C:\HDTool\Applications\RASupport.exe"
            }

#DHCP - This launches DHCP on the current POS Server
        'DHCP' {
Start-Process -File "C:\HDTool\Applications\dhcp.msc"
            }

#Install - This installs the application to C:\HDTool
        'Install' {
Net Use P: \\Domain1\DATA\City\Departments\InformationTechnology\Private\Helpdesk
if(!(Test-Path -Path C:\HDTool)) {
New-Item -Path C:\HDTool -ItemType Directory }
Copy-Item -path P:\HD\App\HDTool\* -destination C:\HDTool\ -recurse
Write-Host 'You have successfully installed the Help Desk Tool'
Net Use P: /Delete
            }

#Update - This updates your current HDTool folder to the latest revision.
        'Update' {
Net Use P: \\Domain1\DATA\City\Departments\InformationTechnology\Private\HelpDesk
if(Test-Path -Path C:\HDTool) {
Remove-Item -Path C:\HDtool -recurse
New-Item -Path C:\HDTool -ItemType Directory}
Copy-Item -Path P:\HD\App\HDTool\* -destination C:\HDTool\ -Recurse
Net Use P: /Delete
            }            

#Rdp - This launches RDP using /v and /admin. It allows us to sign in to a pos server without using up one of the two allowed connections. This uses your Host file.
        'RDP' {
$hostname = Read-Host -Prompt "What is the hostname?"
mstsc /v $hostname /admin
            }

#IW - This launches the IngenWeb website using your default browser. This is where stores view their recommended orders. 
        'IW' {
Start-Process -FilePath http://sm-iris-web.Domain2.CompanyName.com/INGEN/Orders.aspx
            }
#VNC - This allows you to VNC to whichever register or fast lane you need to shadow.
        'VNC' {
$lastoctet = Read-Host -Prompt "What is the last octect from the register's IP address?"
& "C:\HDTool\Applications\Run VNC Viewer.lnk" 205.105.5.$lastoctet
            }

#Menu - This shows a menu of the different options in the tool as well as a brief description.
         'Menu' {
[xml]$xml = get-content -path "C:\HDTool\Xml\HDToolMenu.xml"
$xml.HDToolMenu.MenuOption | Format-table -AutoSize
            }

#IRIS - This launches the IRIS Server Reset tool.
        'Iris' {
Start-Process -Filepath C:\HDTool\Applications\HHTServer32Restart.exe
            }

#This Is The End
     }
pause
 }
 until ($selection -eq 'q')


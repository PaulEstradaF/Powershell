Function Start-HDTools {
<#
    .SYNOPSIS
    A collection of tools and links used by the The Save Mart Companies' IT Support team. 
    .DESCRIPTION
    This tool provides an interface for a collection of different tools used by the IT Support team.
    This tool provides easy access to AD user account information including last failed login attempt,
    lockout verification, unlocking, and resetting account passwords. Using the Store Info tool 
    you can find anything from store or district manager name to field tech name and phone number. 
    HDTools also includes three different directories, AD Phone directory, Cisco Unified Phone Directory,
    and a custom directory gathered from different agents. Links to all common support tools such as, 
    Citrix Director, Remote Assistance, Slack, UCCX, AS400, Scales. There are also web links to common web 
    based applications.

    The second half of this tool includes common tools for troubleshooting registers. You have the option to
    retrieve system and application logs from both registers and fast lanes. This tool also has the
    ability to view how often a register has been rebooted. DHCP and Vnc shortcuts are included as well.

    This tool will be evolving and additional functions will be added.


    Script Name	: HDTools.ps1
    Description	: This script consolidates several different resources and tools that the Save Mart IT Help Desk uses Daily.
    Author      : Paul Estrada
    Last Update	: 5/18/2018
    Keywords	: Save Mart, Help Desk, Store Information, Active Directory Information
    Reference   : 
#>
    [Console]::Title='Help Desk Tools'
    [Console]::WindowWidth=80
    [Console]::WindowHeight=30

    function Show-HDToolsMainMenu {
        param (
            [string]$Title = 'Help Desk Tools'
        )
        cls
        Write-Host " ______________________________________________________________________________" -ForegroundColor 'White'
        Write-Host " ______________________________"-ForegroundColor 'White' -NoNewLine 
        Write-Host "[ $Title ]"-ForegroundColor 'Darkred' -NoNewLine
        Write-Host "_____________________________       " -ForegroundColor 'White'      
        Write-Host ""
        Write-Host "From WorkStation                                                        " -ForegroundColor 'DarkRed'-backGroundColor 'White' 
        Write-Host "  "
        Write-Host "     [SM] SMLan Info         [SMAD2] SMAD2 Info      [SI] Store Info         " -ForegroundColor 'White'
        Write-Host "     [HH] Shadow HH          [Dir] AD Directory      [RA] Remote Assistance  " -ForegroundColor 'White'
        Write-Host "     [CTX] Citrix            [Slack] Slack Page      [Nagios] Nagios Page    " -ForegroundColor 'White'
        Write-Host "     [IRIS] Reboot Server    [S401] Smart401         [S402] Smart402         " -ForegroundColor 'White'
        Write-Host "     [PM] Printer Man.       [1Off] Kyle's 1Off      [IW] IngenWeb Page      " -ForegroundColor 'White'
        Write-Host "     [VL] Register Logs      [RDP] RDP As Admin      [PS] Powershell         " -ForegroundColor 'White'
        Write-Host "     [SMS] SM Scales         [FMS] FM Scales         [DIR+] Corp Directory   " -ForegroundColor 'White'
        Write-Host "     [UCCX] Cisco Finesse    [CS] Cornerstone        [AS] Agent Assignments  " -ForegroundColor 'White'
	    Write-Host "     [Unlock] Unlock AD      [RPW] Reset AD PW								 " -ForegroundColor 'White'
        Write-Host " "
        Write-Host "From POS Server                                                         " -ForegroundColor 'DarkRed' -BackgroundColor 'White'
        Write-Host ""
        Write-Host "     [VWL] CS/FL EventLogs           [VNC] UltraVNC Viewer            "            -ForegroundColor 'White'
        Write-Host "     [DCHP] DHCP In Stores           [LBU] CS/FL - Last Boot Up Time  "            -ForegroundColor 'White'
        Write-Host "     [TMS] TMS Administrator         [TSM] Terminal Services Manager  "            -ForegroundColor 'White'
        Write-Host "     [ASW] ASW Shell                                                  "            -ForegroundColor 'White'
        Write-Host ""                                               
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host ""
        Write-Host " [Install] Installs HD Tools     [Update] Updates Help Desk Tools "                -ForegroundColor 'DarkGray'
        Write-Host ""
        Write-Host ""
        Write-Host " Please make a selection or type "                                                 -NoNewline
        Write-Host "[quit]"                                                                            -ForegroundColor Yellow -backgroundcolor DarkGray -NoNewline
        Write-Host " to exit: "                                                                        -NoNewline
    }

    do {
        Show-HDToolsMainMenu
        [ValidateSet("Install", "Update", "SM", "SMAD2", "SI", "HH", "Dir+", "RA", "Slack", "Nagios", "Ctx", "Iris", "S401",`
        "S402", "PM", "1Off", "IW", "VL", "RDP", "PS", "SMS", "FMS", "DIR", "UCCX", "CS", "AS", "DHCP", "VNC", "TMS", "TSM",`
        "ASW", "Tammy", "Quit", "VWL", "LBU")]   
        [String]$mainSel = Read-Host
        switch ($mainSel) {
<# Workstation Menu Starts #>
            'SM' {
                    cls
                    Write-Host " ______________________________________________________________________________" 
                    Write-Host " _________________________" -NoNewLine
                    Write-Host "[SM Lan Account Information]" -ForegroundColor 'DarkRed' -NoNewLine
                    Write-Host "_________________________"         
                    Write-Host ""
                    Write-Host "" 
                    Write-Host ""
                    Write-Host ""
                    Write-Host " Name:"
                    Write-Host " Department:" 
                    Write-Host " Canonical Name:" 
                    Write-Host " Password Expired:"
                    Write-Host " Password Expired:" 
                    Write-Host " Locked Out:" 
                    Write-Host " Bad Logon Count:" 
                    Write-Host " Last Bad Password Attempt:" 
                    Write-Host " Office:"
                    Write-Host " Office Phone:"
                    Write-Host " IP Phone:"
                    Write-Host " Mobile Phone:"
                    Write-Host " Member Of:"
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    $smLogin = Read-Host -Prompt 'What is the Login Name?'
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    get-aduser -identity $smLogin -properties CanonicalName, department, title, PasswordExpired, LockedOut, PasswordLastSet, BadLogonCount, LastBadPasswordAttempt,  Office, ipPhone, OfficePhone, MobilePhone, MemberOf |
                    Select-Object -Property "Name", "Department", "Title", "CanonicalName", "PasswordExpired", "LockedOut", "PasswordLastSet", "BadLogonCount", "LastBadPasswordAttempt",  "Office", "OfficePhone", "ipPhone", "MobilePhone", "MemberOf"
            } 
            'SMAD2' {
                    cls
                    Write-Host " ______________________________________________________________________________" 
                    Write-Host " _________________________" -NoNewLine
                    Write-Host "[SMAD2 Account Information]" -ForegroundColor 'DarkRed' -NoNewLine
                    Write-Host "__________________________"         
                    Write-Host ""
                    Write-Host "" 
                    Write-Host ""
                    Write-Host ""
                    Write-Host "Name:"
                    Write-Host "Department:" 
                    Write-Host "Canonical Name:" 
                    Write-Host "Password Expired:"
                    Write-Host "Password Expired:" 
                    Write-Host "Locked Out:" 
                    Write-Host "Bad Logon Count:" 
                    Write-Host "Last Bad Password Attempt:" 
                    Write-Host "Office:"
                    Write-Host "Office Phone:"
                    Write-Host "IP Phone:"
                    Write-Host "Mobile Phone:"
                    Write-Host "Member Of:"
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    $smad2Login = Read-Host -Prompt 'What is the Login Name?'
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Get-ADUser -identity $smad2Login -server smad2.savemart.com -properties CanonicalName, department, title, PasswordExpired, LockedOut, PasswordLastSet, BadLogonCount, LastBadPasswordAttempt,  Office, ipPhone, OfficePhone, MobilePhone, MemberOf |
                    Select-Object -Property "Name", "Department", "Title", "CanonicalName", "PasswordExpired", "LockedOut", "PasswordLastSet", "BadLogonCount", "LastBadPasswordAttempt",  "Office", "OfficePhone", "ipPhone", "MobilePhone", "MemberOf"
            }
            'SI' {
                    cls
                    Write-Host " ______________________________________________________________________________" 
                    Write-Host " _____________________________" -NoNewLine
                    Write-Host "[Store Information]" -ForegroundColor 'DarkRed' -NoNewLine
                    Write-Host "______________________________"         
                    Write-Host ""
                    Write-Host "" 
                    Write-Host ""
                    Write-Host "Banner:"
                    Write-Host "Store Number:"
                    Write-Host "District:"
                    Write-Host "District Manager:"
                    Write-Host "Street Address:"
                    Write-Host "City:"
                    Write-Host "Zip Code:"
                    Write-Host "County:"
                    Write-Host "Store Manager:"
                    Write-Host "AGM, GM, or ACSM:"
                    Write-Host "Store Phone Number:"
                    Write-Host "Rx Manager:"
                    Write-Host "Rx Phone Number:"
                    Write-Host "Field Tech:"
                    Write-Host "Field Tech Number:"
                    Write-Host "IRIS Server:"
                    Write-Host "IP Address:"
                    Write-Host "Store Hours:"
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    $siStoreNumber = Read-Host -Prompt "What is the 3 digit store number?"
                    cls
                    Write-Host " "
                    Write-Host " "
                    Write-Host "                                                                     " -BackgroundColor 'White'
                    Write-Host "Store Information                                                    " -ForegroundColor 'DarkRed' -BackgroundColor 'White'
                    Write-Host "                                                                     " -BackgroundColor 'White'

                    [xml]$xml = get-content -path "C:\HDTool\Xml\Storeinfo.xml"
                    $xml.store_information.storeinfo | Where-Object -Property storenumber -eq $siStoreNumber
                    Write-Host ""
            }
            'HH' {
                    cls
                    Write-Host " ______________________________________________________________________________" 
                    Write-Host " __________________________" -NoNewLine
                    Write-Host "[Shadowing An Ordering HH]" -ForegroundColor 'DarkRed' -NoNewLine
                    Write-Host "__________________________"         
                    Write-Host ""
                    Write-Host "" 
                    Write-Host ""
                    Write-Host "Instructions:"
                    Write-Host "    To get the HH IP address go to the Avalanche"
                    Write-Host "    screen then click on Help then Adapater Info."
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    Write-Host ""
                    $HHIP = Read-host -Prompt "What is the Hand Held's IP Address?"
                    cd 'Y:\HD\App\WLRemoteControl MC 4.082'
                    .\WLRemoteControl.exe /action:view /connect:tcpip /device:$HHIP
                    cd c:\
            }
            'Dir+'  { Start-Process -FilePath http://svdirsvc.intranet.savemart.com }
            'Slack' { Start-Process -FilePath https://it-savemart.slack.com/messages }
            'Nagios'{ Start-Process -FilePath http://nagios.intranet.savemart.com/check_mk/index.py?start_url=%2Fcheck_mk%2Fview.py%3Fview_name%3Dsvcproblems }
            'IW'    { Start-Process -FilePath http://sm-iris-web.smad2.savemart.com/INGEN/Orders.aspx }
            'Iris'  { Start-Process -Filepath 'C:\HDTool\Applications\HHTServer32Restart.exe' }
            'RA'    { Start-Process -FilePath "C:\HDTool\Applications\RASupport.exe" }
            'Ctx'   { Start-Process -FilePath 'C:\HDTool\Applications\Citrix Director' }
            'S401'  { Start-Process -FilePath "C:\HDTool\Applications\Smart401.ws" }
            'S402'  { Start-Process -FilePath "C:\HDTool\Applications\Smart402.ws" }
            'PM'    { Start-Process -FilePath "C:\HDTool\Applications\Print Management.msc" }
            'SMS'   { Start-Process -FilePath 'C:\HDTool\Applications\SaveMart Interscale' }
            'FMS'   { Start-Process -FilePath 'C:\HDTool\Applications\FoodMaxx Interscale' }
            'UCCX'  { Start-Process -FilePath 'C:\HDTool\Applications\Cisco Finesse' }
            'CS'    { Start-Process -Filepath 'https://goo.gl/8XkRQO' } #Cornerstone
            'AS'    { Start-Process -Filepath 'https://goo.gl/uxNnYk' } #Share Point Agent Assignments 
            '1off' { 
                Start-Process powershell.exe  -ArgumentList {
                    [Console]::WindowHeight='25'
                    [Console]::WindowWidth='60'
                    [Console]::BackgroundColor='Black'   
                    Write-Host "Please enter a tag to search by:"
                    $tag = Read-Host
                    [xml]$xml = Get-Content -Path "C:\HDTools\XML\HDDirectory.xml"
                    $xml.HDDirectory.entry | Where -Property tags -Like "*$tag*" | 
                    select Name, ContactInfo, OtherInfo | FL 
                    pause
                    }
                }
            'RDP' {
                    $hostname = Read-Host -Prompt "What is the hostname?"
                    mstsc /v $hostname /admin
            }
            'PS' { Start-Process powershell }
            'Dir' {
                    cls
                    Write-Host " ______________________________________________________________________________" 
                    Write-Host " _______________________________" -NoNewLine
                    Write-Host "[Phone Directory]" -ForegroundColor 'DarkRed' -NoNewLine
                    Write-Host "______________________________"
                    Write-Host " "
                    Write-Host " "      
                    Write-Host "  Information:                                                          " -BackgroundColor 'White' -foregroundcolor 'Black'
                    Write-Host " "
                    Write-Host "    This tool searches for phone numbers from Active Directory." -ForeGroundColor 'White'
                    Write-Host "    You can search with the exact name or with the wildcard '*'." -ForeGroundColor 'White'
                    Write-Host " "
                    Write-Host "    Example: Pa*Est*" -ForeGroundColor 'Yellow'
                    Write-Host " "
                    Write-Host "    This would retrieve any phone number information from Active Directory for" -ForegroundColor 'White'
                    Write-Host "    Paul Estrada." -ForegroundColor 'White'
                    Write-Host " "
                    $su = Read-Host -prompt "What is the caller's name?" 
                    Get-Aduser -Filter {Name -Like $su } -Properties * | Select Name, Mobilephone, Telephonenumber | Format-Table -Autosize -Wrap
            }

    <# Workstation Menu Ends #>

    <# From POS Menu Starts #> 
            #Option 3 - This copies the system log from the specified register or fast lane and places it in a folder named Registers on your POS Desktop

            'DHCP' {
                    Start-Process -File "C:\HDTool\Applications\dhcp.msc"
            }
            'VNC' {
                    $lo = Read-Host -Prompt "What is the last octect from the register's IP address?"
                    & "C:\HDTool\Applications\Run VNC Viewer.lnk" 205.105.5.$lo
            }
            'TMS' {
                    Start-Process 'C:\HDTool\Applications\TMS Administrator'
            }
            'TSM' {
                    Start-Process 'C:\HDTool\Applications\Terminal Services Manager'
            }
            'ASW' {
                    Start-Process 'C:\HDTool\Applications\ASWShell'
            }
    <# From POS Menu Ends #>

    <# Help Desk Tool Configuration Menu Starts #>
            'Install' {
                    Net Use P: \\SM.LAN\DATA\Modesto\Departments\InformationTechnology\Private\SUPPORTCENTER
                    if(!(Test-Path -Path C:\HDTools)) {
                    New-Item -Path C:\HDTools -ItemType Directory }
                    Copy-Item -path P:\HD\App\HDTools\* -destination C:\HDTools\ -recurse
                    Write-Host 'You have successfully installed the Help Desk Tools'
                    Net Use P: /Delete
            }
            'Update' {
                    Net Use P: \\SM.LAN\DATA\Modesto\Departments\InformationTechnology\Private\SUPPORTCENTER
                    if(Test-Path -Path C:\HDTools) {
                    Remove-Item -Path C:\HDtools -recurse
                    New-Item -Path C:\HDTools -ItemType Directory}
                    Copy-Item -Path P:\HD\App\HDTools\* -destination C:\HDTools\ -Recurse
                    Net Use P: /Delete
            }          
    <# Help Desk Tool Configuration Menu Ends #>

    <# Testing Starts #>
            'Tammy' {
            Start-Process -FilePath 'https://goo.gl/8XkRQO' #Cornerstone
            Start-Process -FilePath 'https://goo.gl/uxNnYk' #Agent Assigments
            Start-Process -FilePath 'https://goo.gl/c4F39N' #Connected Payments
            Start-Process -Filepath 'https://goo.gl/CbfJqb' #UCCX
            }
		    'Unlock' { 	Function unlock-hdaccount {
						    $id = Read-host -prompt "What is the login id?"
						    unlock-adaccount -Identity $id -server corp-dc1
						    }
					    unlock-hdaccount
					    Write-output "The account $id has been unlocked." }
		    'RPW' { Function Reset-HDadpassword {
					    $rpwid = Read-Host -Prompt "What is the SM Lan username?"
					    $rpwnewpassword = Read-Host -prompt "Please provide a temporary password" -AsSecureString
					    Set-ADaccountpassword -identity $rpwid `
										      -Newpassword $rpwnewpassword `
										      -Server Corp-DC1 `
										      -Confirm:$false `
										      -Reset `
										      -Verbose;
					    Set-ADUser -Identity $Identity -ChangePasswordAtLogon:$True -verbose
					    Write-Output "Password for $identity was successfully changed."
 				    }
				    Reset-HDadpassword
			      }
    <# Testing Ends #>

            }
    pause
    }
    Until ($mainSel -eq 'quit')
}

Start-HDTools

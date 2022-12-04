<#.Synopsis
    Active Directory Feed. Offboards and updates Manager,
    Title, Position Code, Office Location, and Hire Date Active 
    Directory fields.

    The purpose of this script is to ensure that we have a central
    point for employee information that can flow to Active Directory,
    Ping SSO, and Office365/Azure environment (Delve
    and Address Book). 
.DESCRIPTION
    This script relies on an automated process of exporting AS400
    user information to an encrypted .csv file which then gets sent
    to the SFTP server using SFTP. The file is encrypted using 
    OpenPGP with a public key on the  server. This script 
    decrypts the file, places the the file in a decrypted folder, 
    imports the decrypted file then processes the information in the
    following order:
        1. 
        1. Sorts users into two variables: NotInAd, UpdateAD
        2. Users in the NotInAD variable are processed as new users
           - This is currently disabled.
        3. Users in the UpdateAD variable who have Term Date populated 
           in the AS400 Export will be offboarded. If the account is
           already offboarded no changes will be made.
           [1] Disable Account
           [2] Move to offboarded OU
           [3] Remove manager
           [4] Remove all Active Directory groups except Office365
           [5] Changes account description to 'Disabled by AS400 Feed.'
               followed by the current date.
        4. Users in the UpdateAD variable will have the following
           fields updated on their Active Directory account using
           information from the exported AS400 information.
           [1] Manager
           [2] Title
           [3] PositionCode {ExtensionAttribute4}
           [4] Hire Date {ExtensionAttribute2}
           [5] Location {Office}
    The decrypted csv file that is created at the beginning of the
    script is deleted once it is stored in memory.

    This process will be executed using PDQ to run from the 'server name'
    server each night at 11:30PM. This script will create a log 
    with the user's account information prior to the change so that 
    they can be reverted if needed. That log will be encrypted.
.Notes
    Created by: Paul Estrada and Sean Isensee
    Version: 1.0
    Previous Version: .9
    Original Script Location: \\Path\To\Projects\AS400
    Scheduled Implementation Date: 7/6/2020
    Original script was created in early 2019 and contained the main 
    logic. Paul updated the following information when assigned to
    this project:
        [1] Logic to encrypt/decrypt csv
        [2] Error handling
        [3] Logging
        [4] Modified the offboarding process to include moving OU,
            removing manager, removing AD groups.
        [5] Added items related to PingSSO (adding and removing from
            AD Group)
.Link
    
#>
##Settings - UI Customization and script metrics
$Host.UI.RawUI.BackgroundColor = 'Black'
Clear-Host
$StartTime = Get-Date
Write-Host "                                                                                      " -BackgroundColor 'DarkRed' 
Write-host "[$StartTime] [**] - Starting Infinium to Active Directory Script - [**]      " -ForeGroundcolor 'White' -BackgroundColor 'DarkRed'
Write-Host "                                                                                      " -BackgroundColor 'DarkRed'

##Logs - Creates new file if non exists, renames file if larger than 20MB
$LogFileLocation = "$ENV:ProgramData\Path\To\Logs\LogFile.txt"
$TestLogPath = Test-Path -Path $LogFileLocation

If ($TestLogPath -eq $False) {
    Try { 
        New-Item -Path $logFileLocation -Force | Out-Null
    }
    Catch { 
        Write-Host "[-] Failed to create a new log file." -ForeGroundcolor Red
    }
} Else {
    Write-Host "[+] Verified log file already exists. " -ForeGroundcolor Cyan
    $LogFileInfo = Get-ItemProperty $LogFileLocation
}

If ( $LogFileInfo.Length -gt 20mb) {
    Write-Host "[!] $logFileLocation is larger than 20MB. Archiving old file and creating new log." -ForegroundColor Cyan
    $CurrentDate = Get-Date
    $ShortDate = $CurrentDate.ToShortDateString().replace('/','')
    Try { 
        Rename-Item $logFileLocation -NewName "$ShortDate.AS400ToInfinium.Txt"
        Try { 
            New-Item -Path $logFileLocation -Force | Out-Null 
        } Catch { }
    } Catch {
        Write-Host "[-] Failed to rename old log file." -ForegroundColor Red
    }
}

##ADBackup 
Try { 
    $ADBackupStartTime = Get-Date
    Write-Host "[$ADBackupStartTime] [~][~] Creating AD User back up for properties that could be affected by this script." -ForegroundColor Yellow
    Write-Output "[$ADBackupStartTime] [~][~] Creating AD User back up for properties that could be affected by this script." | Out-File $LogFileLocation -Append
    $ADBackup = Get-ADUser -filter "Name -like '*'" -Properties ExtensionAttribute1,ExtensionAttribute2,ExtensionAttribute3,Extensionattribute4, `
                                                    ExtensionAttribute5,Manager,MemberOf,Office,Division,Department,Mail,EmployeeType, `
                                                    Title,DisplayName,UserprincipalName,Title,telephoneNumber,OfficePhone,Mail,MobilePhone, `
                                                    CanonicalName,DistinguishedName,emailAddress 
    $CurrentTime = Get-Date
    $ShortDate = $CurrentTime.ToShortDateString().Replace('/','')
    $ADBackupClixml = "C:\ProgramData\Path\To\Logs\Name\$ShortDate.Name"
    Try {
        $AdBackup | Export-Clixml -Path $ADBackupClixml -ErrorAction Stop 
        Write-host "[+] Successfully exported AD Back up information to $ADBackupClixml." -ForegroundColor Cyan
        $CurrentTime = Get-Date
        Write-Output "[$CurrentTime] [+] Succesfully exported AD User back up information to $ADBackupClixml." | Out-File $LogFileLocation -Append
    } Catch {
        Write-Host "[-] Gathered AD Back up information but failed to export the clixml to $ADBackupClixml." -ForegroundColor Red
        $CurrentTime = Get-Date
        Write-Output "[$CurrentTime] [-] Gathered AD User back up information but failed to export the clixml to $ADBackupClixml." | Out-File $LogFileLocation -Append
    }
} Catch {
    Write-Host "[-] Failed to gather AD User back up information." -ForegroundColor Red 
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [-] Failed to gather AD User back up information." | Out-File $LogFileLocation -Append
}

##SFTP To 'server name'
$CSVFileOnSFTP = '\\Path\To\File\File.csv.pgp'
$EncryptedCSV = "$Env:ProgramData\Path\To\Encrypted\File.csv.pgp"
$CurrentTime = Get-Date
Write-host ""   
Write-Host "[$CurrentTime] [~][~] Checking for encrypted csv file." -ForegroundColor 'White' -BackgroundColor 'DarkRed' 
Write-Output "" | Out-File $logFileLocation -Append
Write-Output "[$CurrentTime] [~][~] Checking for encrypted csv file." | Out-File $logFileLocation -Append
$WINSFTFile = Test-Path "$CSVFileOnSFTP"
if ($WINSFTFile -eq $True) {
    Write-Host "[+] File was found. Copying file to Server."
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [+] File was found. Copying file to 'Server Name'." | Out-File $logFileLocation -Append
    Try {
        Copy-Item -Path $CSVFileOnSFTP -Destination $EncryptedCSV -Force -ErrorAction Stop
        Write-Host "[+] Successfully Copied $CSVFileOnSFTP to $EncryptedCSV." -ForeGroundcolor Cyan
        $CurrentTime = Get-Date
        Write-Output "[$CurrentTime] [+] successfully copied $CSVFileOnSFTP to $EncryptedCSV." | Out-File $logFileLocation -Append
    } catch {
        Write-Host "[-] Failed to copy $CSVFileOnSFTP to $EncryptedCSV. Please check manually." -ForeGroundcolor DarkCyan
        $CurrentTime = Get-Date
        Write-Output "[$CurrentTime] [-] Failed to copy $CSVFileOnSFTP to $EncryptedCSV. Please check manually." | Out-File $LogFileLocation -Append
    }
}

##Decrypting
###Settings
$GPG = "${Env:ProgramFiles(x86)}\GnuPG\bin\gpg.exe"
$PassphraseFile = "$ENV:ProgramData\Path\To\Scripts\"
$DecryptedCSV = "$ENV:ProgramData\Path\To\Decrypted\aduser.csv"

$CurrentTime = Get-Date
Write-Host ""
Write-Host "[$CurrentTime] [~][~] Beginning Decryption Process." -ForeGroundcolor 'White' -BackgroundColor 'DarkRed'
Write-Output "[$CurrentTime] [~][~] Beginning Decryption Process. " | Out-File $logFileLocation -Append
Try { 
    Write-host "[+] Attempting to decrypt $EncryptedCSV." -ForeGroundcolor Cyan
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [+] Attempting to decrypt $EncryptedCSV." | Out-File $logFileLocation -Append
    Invoke-Command -ScriptBlock {
        & "$GPG" --output $DecryptedCSV --batch --pinentry-mode=loopback --passphrase-file $PassphraseFile --decrypt $EncryptedCSV
    } -ErrorAction Stop
    Write-host "[+] Successfully decrypted $EncryptedCSV." -ForeGroundcolor Cyan
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [+] Successfully decrypted $EncryptedCSV." | Out-File $logFileLocation -Append
} Catch {
    Write-Host "[-] Failed to decrypt $EncryptedCSV. Please verify manually." -ForeGroundcolor Red
    $CurrentTime = Get-Date
    Write-output "[$CurrentTime] [-] Failed to decrypt $EncryptedCSV. Please verify manually." | Out-File $logFileLocation -Append
}

##Imports Decrypted File
Try {
    $csv = Import-Csv $DecryptedCSV -ErrorAction Stop | Sort 'Employee #'
    Write-Host "[+] Successfully imported $DecryptedCSV to memory." -ForeGroundcolor Cyan
    $CurrentTime = Get-Date
    Write-output "[$CurrentTime] [+] Successfully imported $DecryptedCSV to memory." | Out-File $logFileLocation -Append
} Catch {
    Write-Host "[-] Failed to import $DecryptedCSV." -ForeGroundcolor Red
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [-] Failed to import $DecryptedCSV." | Out-file $logFileLocation -Append
}
#Remove DecryptedFile
Try {
    Remove-Item $DecryptedCSV -Force
    Write-Host "[+] Successfully deleted $DecryptedCSV." -ForeGroundcolor Cyan
    $CurrentTime = Get-Date
    Write-output "[$CurrentTime] [+] Successfully deleted $DecryptedCSV." | Out-File $logFileLocation -Append
} Catch {
    Write-host "[-] Failed to delete $DecryptedCSV." -ForeGroundcolor Red
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [-] Failed to delete $DecryptedCSV." | Out-File $logFileLocation -Append
} 

#Remove CSV on SFTP
Try {
    Remove-Item $CSVFileOnSFTP -Force
    Write-Host "[+] Successfully deleted $CSVFileOnSFTP." -ForeGroundcolor Cyan
    $CurrentTime = Get-Date
    Write-output "[$CurrentTime] [+] Successfully deleted $CSVFileOnSFTP." | Out-File $logFileLocation -Append
} Catch {
    Write-host "[-] Failed to delete $CSVFileOnSFTP." -ForeGroundcolor Red
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [-] Failed to delete $CSVFileOnSFTP." | Out-File $logFileLocation -Append
} 
$notInAD = @{}
$updateAD = @{}
$disableAD = @{}
$domain = '@savemart.com'
$PreProcessingADUserInfo = "$ENV:ProgramData\Path\To\Logs\PreProcessingADUserInfo.csv"
$PreProcessingCSVUserInfo = "$ENV:ProgramData\Path\To\Logs\PreProcessingCSVUserInfo.csv"

$CurrentTime = Get-Date
Write-host ""
Write-Output " " | Out-File $LogFileLocation -Append
Write-Host "[$CurrentTime] [~][~] Importing necessary custom Powershell commands." -ForeGroundcolor 'White' -BackgroundColor 'DarkRed'
Write-Output "[$CurrentTime] [~][~] Importing necessary custom Powershell commands." | Out-File $LogFileLocation -Append

##Modules - Required Custom Commands/Modules
##~Import Load-ExchangeCommands
Try {
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [!] Attempting to import Load-ExchangeCommands.ps1" | Out-File $LogFileLocation -Append 
    Import-Module \\Path\To\powershell\commands\Load-ExchangeCommands.ps1 -ErrorAction Stop 
    $CurrentTime = Get-Date
    Write-Host "[+] Successfully imported Load-ExchangeCommands.ps1." -ForeGroundcolor Cyan
    Write-Output "[$CurrentTime] [+] Successfully Imported Load-ExchangeCommands.ps1." | Out-File $LogFileLocation -Append
}
Catch { 
    Write-host "[-] Failed to import the Load-ExchangeCommands.ps1" -ForegroundColor Red 
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [-] Failed to import Load-ExchangeCommands.ps1." | Out-File $LogFileLocation -Append
}
<##Run Load-ExchangeCommands -- Disabled for now (No need to connect at this time)- PE
$CurrentTime = Get-Date
Write-Output "[$CurrentTime] - Attempting to run Load-ExchangeCommands." | Out-File $LogFileLocation -Append
Try { 
    Load-ExchangeCommands -ErrorAction Stop -WarningAction SilentlyContinue
    Clear-Host
    Write-Host "[[ Loaded On Prem Exchange Powershell Commands Successfully. ]]"
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] -- Successfully ran Load-ExchangeCommands." | Out-File $LogFileLocation -Append
}
Catch { 
    Write-Host "Unable to load the on prem Exchange powershell commands."
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] -- Failed to run Load-ExchangeCommands." | Out-File $LogFileLocation -Append 
} 
#>

##~Import New-o365RemoteMailbox.PS1
Try { 
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [!] Attempting to import New-o365RemoteMailbox.ps1." | Out-File $LogFileLocation -Append
    Import-Module \\path\to\powershell\Commands\New-o365RemoteMailbox.ps1 -ErrorAction Stop
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [+] Successfully imported New-o365RemoteMailbox.ps1." | Out-File $LogFileLocation -Append
    Write-Host "[+] Successfully imported New-O365RemoteMailbox.ps1" -ForeGroundcolor 'White'
}
Catch { 
    Write-Host "[!] Failed to import the New-o365RemoteMailbox module." -ForegroundColor Red
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [] Failed to import New-o365RemoteMailbox.ps1." | Out-File $LogFileLocation -Append
}

##~Import Start-ADSync.PS1
Try {
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [!] Attempting to import Start-ADSync.ps1." | Out-File $LogFileLocation -Append
    Import-Module \\Path\To\powershell\Commands\Start-ADSync.ps1 -ErrorAction Stop
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [+] Successfully imported Start-ADSync.ps1." | Out-file $LogFileLocation -Append
    Write-Host "[+] Successfully imported Start-ADSync.ps1." -ForeGroundcolor 'Cyan'
}
Catch { 
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] [-] Failed to import Start-ADSync.ps1." | Out-File $LogFileLocation -Append
    Write-Host "[-] Failed to import Start-ADSync.ps1." -ForeGroundcolor Red
}

##Gathers AD Information for each Employee ID from the CSV
$CurrentTime = Get-Date
Write-host ""
Write-Output " " | Out-File $LogFileLocation -Append
Write-Host "[$CurrentTime] [~][~] Sorting Users from CSV." -ForeGroundcolor 'White' -BackgroundColor 'DarkRed'
Write-Output "[$CurrentTime] [~][~] Sorting Users from CSV." | Out-File $LogFileLocation -Append

foreach ($EmployeeID in $csv.'Employee #'.TrimEnd()) {
    Write-Host " "
    $CurrentTime = Get-Date
    Write-Host "[$CurrentTime] [!] Processing EmployeeID: $EmployeeID." -ForegroundColor Yellow
    Write-Output "[$CurrentTime] [!] Processing EmployeeID: $EmployeeID." | Out-File $logFileLocation -Append
    Try { 
        $CurrentTime = Get-Date
        Write-Host "[!] Gathering AD Info for $EmployeeID." -ForeGroundcolor Yellow
        Write-output "[$CurrentTime] [!] Gathering AD Info for $EmployeeID." | Out-File $logFileLocation -Append
        $CurrentlyChecking =  Get-ADUser -Identity $EmployeeID -Properties * -ErrorAction Stop
        $CurrentTime = Get-Date
        Write-Host "[+] Successfully gathered AD info for $EmployeeID, $($CurrentlyChecking.DisplayName)." -ForeGroundcolor Green
        Write-Output "[$CurrentTime] [+] Successfully gathered AD info for $EmployeeID, $($CurrentlyChecking.Displayname)." | Out-File $logFileLocation -Append
    }
    Catch { 
        $CurrentlyChecking = $Null
        $CurrentTime = Get-Date
        Write-Host "[-] Failed to gather AD info for $EmployeeID." -ForeGroundcolor Red
        Write-Output "[$CurrentTime] [-] Failed to gather AD info for $EmployeeID." | Out-File $logFileLocation -Append
    }
    ##NotInAD - If EmployeeID Does Not exist in AD, adds the EmployeeID to the variable notInAD 
    if ($CurrentlyChecking -eq $Null) {
        $CurrentTime = Get-Date
        Write-Output "[$CurrentTime] [!] $EmployeeID Does not have an AD Account." | Out-File $logFileLocation -Append
        Write-Output "[$CurrentTime] [+] Adding $EmployeeID to NotInAD Variable." | Out-File $logFileLocation -Append
        Write-Host "[!] $EmployeeID does not have an AD Account." -ForegroundColor DarkCyan
        Write-Host "[+] Adding $EmployeeID to NotInAD variable." -ForegroundColor Cyan
        Try { 
            $notInAD.Add($EmployeeID,'NewUser')
            $CurrentTime = Get-Date
            Write-Host "[+] Successfully added $EmployeeID to NewUser variable." -ForeGroundcolor Cyan
            Write-Output "[$CurrentTime] [+] $EmployeeID being processed as a new user." | Out-File $LogFileLocation -Append
        } 
        Catch { 
            Write-Host "[-] Failed to add $EmployeeID to NotInAD variable." -ForegroundColor Red 
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] $EmployeeID is not found in AD but unable to add them to NotInAD variable." | Out-File $LogFileLocation -Append
        }
    }
    ##UpdateAD - If EmployeeID does exist in AD adds the EmployeeID to the variable UpdateAD
    else {
        Try { 
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [+] Adding $EmployeeID to UpdateAD Variable." | Out-File $logFileLocation -Append
            Write-Host "[+] Adding $EmployeeID to updateAD variable." -ForegroundColor Cyan
            $updateAD.Add($EmployeeID,'UpdateAD')
        }
        Catch { 
            Write-Host "[-] Failed to add $EmployeeID to updateAD variable." -ForegroundColor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] $EmployeeID was found in AD but was unable to add them to the UpdateAD variable." | Out-File $LogFileLocation -Append
         }
    }
}

##~> Script Processing Metrics
$adchecktime = Get-Date

##NotInAD - Processes new account creation for each user in the notInAD variable.
$CurrentTime = Get-Date
Write-Output "[$CurrentTime] - Starting to process New Users." | Out-File $LogFileLocation -Append
Write-Host ""
Write-Host "[$CurrentTime] [[ Starting to process New Users. ]]" -ForegroundColor 'White' -BackgroundColor 'DarkRed' 

<## Commenting out New User Creation for now. 6/29/20 - 
foreach ($NewUser in $notInAD.keys) {
    Write-Output ""
    Write-Host "Processing new account for $newUser." -ForegroundColor Cyan
    $CurrentTime = Get-Date
    Write-Output "[$CurrentTime] -- Processing new account for $newUser." | Out-File $LogFileLocation -Append

    ## Gathers information from imported CSV for the user currently being processed
    $NewUserInfo = $CSV | Select-Object * | Where-Object 'Employee #' -eq $NewUser
    $newDisplayName = $NewUserInfo.'First Name' + ' ' + $NewUserInfo.'Last Name'
    $UPN = $NewUserInfo.'Employee #' + '@Company.com'
    $Password = "Welcome$($Newuser.substring($NewUser.length -3))@"
    $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
#   $newCell = $NewUserInfo.'cell Phone' 
#   $newformattedcell = $newcell -replace "[^0-9]",""
#   $newformattedcell = $newformattedcell.Substring(0)
#   $newformattedcell = “{0:(###) ###-####}” -f [int]$newformattedcell

    ## Creating new account
    Try {
        New-ADUser -SamAccountName $NewUserInfo.'Employee #' `
                -GivenName $NewUserInfo.'First Name' `
                -Surname $NewUserInfo.'Last Name' `
                -Title ($NewUserInfo.'Title').TrimStart().TrimEnd() `
                -Manager $NewUserInfo.'Reports To' `
                -EmployeeID $NewUserInfo.'Employee #' `
                -UserPrincipalName $UPN `
                -Department $NewUserInfo.'Department Name' `
                -Name $newDisplayName `
                -Path "OU=NewUsers,OU=People,OU=--,DC=,DC=Lan" `
                -AccountPassword $securePassword `
                -DisplayName $newDisplayName `
                -Confirm:$False -Verbose `
                -Enabled $True -ErrorAction Stop `
                -ChangePasswordAtLogon $True
    #               -MobilePhone $NewFormattedCell
    }
    Catch {
        Write-Host "[Error] - Failed to create account for $newUser. Please verify manually." -ForeGroundcolor  DarkCyan
    } 
    
    if ($AccountCreated -eq $True) {
        Start-Sleep -Seconds 2
        ## Adds Hire Date
        Try { 
            Set-AdUser -Identity $NewUser -Add @{extensionAttribute2=$NewUserInfo.'Hire Date'} -ErrorAction Stop
        }
        Catch {
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Failed to add the new hire date for $NewUser." | Out-File $LogFileLocation -Append
        }

        ## Adds Position Code 
        Try {
            Set-ADUser -Identity $NewUser -Add @{extensionAttribute4=$NewUserInfo.'Position Code'} -ErrorAction Stop
        }
        Catch {
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Failed to add the Position Code for $NewUser." | Out-File $LogFileLocation -Append
        }
    }

    ## Creates Mailbox for current user being processed.
    $MailboxCreated = $False
    While ($MailboxCreated -eq $False) {
        Try { 
            New-O365RemoteMailbox -EmployeeID $NewUser -ErrorAction Stop | Out-Null
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Created remote mailbox for $newUser." | Out-File $LogFileLocation -Append
            $MailboxCreated = $True
        }
        Catch { 
            Write-Host "[Error] Could not create a remote mailbox for $newUser."
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Could not create remote mailbox for $newUser." | Out-File $LogFileLocation -Append
            Start-Sleep -Seconds 20
        }
    }

    ## Adds user to the 'Ping SSO ' AD Group
    $AddedtoPingGroup = $False
    While ($AddedtoPingGroup -eq $False) {
        Try { 
            Add-ADGroupMember -Identity 'Ping ' -Members $newUser
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Added $Newuser to 'Ping' AD Group. " | Out-File $LogFileLocation -Append
            $AddedtoPingGroup = $True
        }
        Catch { 
            Write-Host "[Error] Could not add $NewUser to 'Ping' AD Group." -ForegroundColor DarkCyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Could not add $NewUser to the 'Ping ' AD Group." | Out-File $LogFileLocation -Append
        }
    }

    ## Adds user to the 'Office365' AD Group.
    $AddedToO365Group = $False
    While ($AddedToO365Group -eq $False) {
        Try {
            Add-ADGroupMember -Identity 'Office365' -Members $NewUser -ErrorAction Stop
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Added $NewUser to the 'Office365' AD Group." | Out-File $LogFileLocation -Append
            $AddedToO365Group = $True
        }
        catch { 
            Write-Host "[Error] Could not add $EmployeeID to 'Office365' AD Group." -ForegroundColor DarkCyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] - Could not add $NewUser to the 'Office365' AD Group." | Out-File $LogFileLocation -Append
        }
    }  
} 
#>

## Processes Updates/Changes to User Accounts already in Active Directory. Users in UpdateAD variable.
##~> Replaces whatever is in there now, no need to verify. Currently updates Last Name, Mobile, Manager.
$CurrentTime = Get-Date
Write-output "" | Out-file $LogFileLocation -Append
Write-Output "[$CurrentTime] [~][~] Starting to process Updates and Offboardings" | Out-File $LogFileLocation -Append
Write-host " "
Write-Host "[$CurrentTime] [~][~] Starting to process Updates and Offboarding." -ForegroundColor 'White' -BackgroundColor 'DarkRed' 

foreach ($User in $updateAD.keys.TrimEnd()) {
    Write-Host ""
    $CurrentTime = Get-Date
    Write-Host "[$CurrentTime] [!] Gathering information for $User from the imported CSV." -ForeGroundcolor Yellow
    Write-Output "[$CurrentTime] [!] Gathering information for $User from the imported CSV." | Out-File $LogFileLocation -Append
    Try {
        $CheckAccount = $CSV | Where-Object 'Employee #' -eq $user -ErrorAction Stop
        Write-Host "[+] Successfully found $User's, $($CheckAccount.'First Name') $($CheckAccount.'Last Name'), information in CSV." -ForeGroundcolor Cyan
    } Catch {
        $CheckAccount  = $Null
        Write-Host "[-] Failed to find $User's information in CSV." -ForeGroundcolor Red
    }
    
    ##Manager Info 
    ## -- Searches $user's AD account for the manager field.
    Try {
        $CurrentADManager = (Get-Aduser -Identity $User -Properties Manager -ErrorAction Stop).Manager 
        Write-Host "[+] Current AD manager field on $($User)'s account is $CurrentADManager." -ForeGroundcolor Cyan
    }
    catch {
        $CurrentADManager = $Null
        Write-Host "[-] Failed to find a manager for $user. Please verify that account is not already disabled." -ForeGroundcolor Red
    }
    ## -- Using the information found above ( Manager field from User's AD Account)
    ## -- Searches AD for the manager's account.
    Try {
        $CurrentADManagerInfo = Get-Aduser -Identity "$CurrentADManager" -ErrorAction Stop
        Write-Host "[+] Successfully gathered information for $User's current AD manager, $CurrentADManager." -ForeGroundcolor Cyan
    } 
    Catch {
        $CurrentADManagerInfo = $Null
        Write-Host "[-] Failed to gather information for $User's current AD Manager." -ForegroundColor Red
    }
    ## New manager information coming in from AS400 CSV
    Try {
        $NewManagerInfo = Get-ADUser -Identity $CheckAccount.'Reports To'.TrimEnd() -Properties * -ErrorAction Stop
        Write-Host "[+] Successfully gathered information for $User's NEW Manager, $($CheckAccount.'Reports To')." -ForeGroundcolor Cyan
    } Catch {
        $NewManagerInfo = $Null
        Write-Host "[-] Failed to gather information for $User's NEW Manager, $($CheckAccount.'Reports To')." -ForeGroundcolor Red
        if ($user -eq 'specialID') {
            $NewManagerInfo = Get-Aduser BOD -Properties *
        }
    } 

    ## Checks if the account is already disabled.
    Try {
        $CurrentADUserInfo = Get-ADUser -Identity $User -Properties *
        Write-Host "[+] Successfully gathered current AD Information for $User." -ForeGroundcolor Cyan
    } Catch {
        $CurrentADUserInfo = $Null
        Write-Host "[-] Failed to gather information for $User." -ForeGroundcolor Red
    } 

    ##BackUp - Gathers user information prior to changes being done on this feed.
    $CurrentADUserInfo | 
        Select-Object SamAccountName,GivenName,SurName,DisplayName,Title,
                      @{l="Manager";e={$CurrentADManagerInfo.SamAccountName}},
                      Mail,@{l="HireDate";e={$_.ExtensionAttribute2}},
                      @{l="PositionCode";e={$_.ExtensionAttribute4}},
                      @{l="Office";e={$_.Location}},EmployeeType  | Out-File $PreProcessingADUserInfo -Append
    
    ## Gathers info from the CSV with which to update the user info on.
    $Props = [ordered]@{
        EmployeeID = $CheckAccount.'Employee #'.TrimEnd()
        FirstName = $CheckAccount.'First Name'.TrimEnd()
        LastName = $CheckAccount.'Last Name'.TrimEnd()
        DisplayName = "$($CheckAccount.'First Name') $($CheckAccount.'Last Name')"
        Title = ($CheckAccount.'Title').TrimStart().TrimEnd()
        Manager = $NewManagerInfo.Name
        ManagerID = $NewManagerInfo.SamAccountName
        Email = "$($CheckAccount.'First Name').$($CheckAccount.'Last Name')@Domain.com"
        Exempt = $CheckAccount.'Exempt/Non Exempt'.TrimEnd()
        HireDate = $CheckAccount.'Hire Date'.TrimEnd()
        PositionCode = $CheckAccount.'Position Code'.TrimEnd()
        Office = $CheckAccount.'Location Description'.TrimEnd()
        EmployeeType = $Null
    }
    $UpdateUser = New-Object -TypeName psobject -Property $Props
    $UpdateUser | Out-File $PreProcessingCSVUserInfo -Append
    ## If the user has a term date in the CSV it disables the account.
    ## Else imports whatever changes are coming in from CSV.
    if ($CheckAccount.'Term Date' -gt 0) {
        $CurrentTime = Get-Date
        ## If the account is currently enabled it goes through the offboarding process.
        If ($CurrentADUserInfo.Enabled -eq $True) {
            Write-Output "[$CurrentTime] - $User has a Term Date on the imported CSV. Disabling account and moving to offboarded OU." | Out-File $LogFileLocation -Append
            Write-Host "[ Disabling the account for $User, $($CheckAccount.'First Name') $($CheckAccount.'Last Name'). ]" -ForegroundColor Red
            $disableAD.Add($User,'DisabledThisAccount')
            ##Offboarding - Disables account, removes manager, modifies description.       
            Try { 
                Set-ADUser -Identity $User -Enabled $False -Manager $Null -Description "Disabled by AS400 Feed. $CurrentTime." -ErrorAction Stop
                $CurrentTime = Get-Date
                Write-Host "[!] Disabled account for $User." -ForeGroundcolor DarkCyan
                Write-Output "[$CurrentTime] - Disabled account for $User." | Out-File $LogFileLocation -Append        
            } catch {
                $CurrentTime = Get-Date
                Write-Host "[-] Failed to disable account for $User." -ForeGroundcolor Red
                Write-Output "[$CurrentTime] - Failed to disable account for $User." | Out-File $LogFileLocation -Append
            }
            ##Offboarding - Moves to Offboarded OU
            Try {
                Move-ADObject -Identity $CurrentADUserInfo.DistinguishedName -TargetPath "OU=Feed,OU=Offboard,OU=-Domain,DC=Private,DC=LAN" -ErrorAction Stop
                Write-Host "[!] Moved $user's account to 'OU=Feed,OU=Offboard...'" -ForeGroundcolor DarkCyan
                $CurrentTime = Get-Date
                Write-Output "[$CurrentTime] [!] Moved $user's account to 'OU=Feed,OU=Offboard...'" | Out-File $logFileLocation -Append
            }
            Catch {
                $CurrentTime = Get-Date
                Write-Output "[$CurrentTime] [-] Failed to move $User's account to the offboarded OU." | Out-File $LogFileLocation -Append
                Write-Host "[-] Failed to move $User's account to the offboarded OU. Please do this step manually." -ForegroundColor Red
            }
            ##Offboarding - Updates Term Date
            Try {
                Set-AdUser -Identity $User -Add @{extensionAttribute3=$CheckAccount.'Term Date'} -ErrorAction Stop
                Write-Host "[!] Set term date for $User to $($CheckAccount.'Term Date')." -ForeGroundcolor DarkCyan
                $CurrentTime = Get-Date
                Write-Output "[$CurrentTime] [!] Set term date for $User to $($CheckAccount.'Term Date')." | Out-File $LogFileLocation -Append
            }
            Catch {
                $CurrentTime = Get-Date
                Write-Host "[-] Failed to add Term Date to $User's disabled account." -ForeGroundcolor Red
                Write-Output "[$CurrentTime] [-] Failed to add Term Date to $User's disabled account." | Out-File $LogFileLocation -Append
            }
            ##Offboarding - Removes from 'Ping' group
            Try {
                Remove-ADGroupMember -Identity 'Ping' -Members $User -Confirm:$False -ErrorAction Stop 
                $CurrentTime = Get-Date
                Write-Output "[$CurrentTime] [!] Removed $User from 'Ping ' AD Group." | Out-File $LogFileLocation -Append
                Write-Host "[!] Removed $User from 'Ping 2' AD Group." -ForeGroundcolor DarkCyan
            }
            Catch {
                Write-Host "[-] Failed to remove $User from 'Ping '. Please do this step manually." -ForegroundColor Red
                $CurrentTime = Get-Date
                Write-Output "[$CurrentTime] [-] Failed to remove $User from 'Ping '. Please do this step manually." | Out-File $LogFileLocation -Append
            }
        }
        ## If the account is already disabled, no changes are made.
        Else {
            Write-Host "[!] Account for $user, $($CheckAccount.'First Name') $($CheckAccount.'Last Name') is already disabled." -ForegroundColor White
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [!] Account for $User, $($CheckAccount.'First Name') $($CheckAccount.'Last Name') is already disabled." | Out-File $logFileLocation -Append 
        }
    } Else {
<#      
        ##?$newCell = $csv | Where-Object 'Employee #' -eq $user | Select-Object 'Cell Phone' 
        ##?$newformattedcell = $newcell -replace "[^0-9]"," "
        ##?$newformattedcell = $newformattedcell.Substring(0)
        #$newformattedcell = “{0:(###) ###-####}” -f [int]$newformattedcell
#>
        Write-Host "" 
        Write-Host "Current Active Directory Account Information for $($UpdateUser.DisplayName)." -ForeGroundcolor Yellow
        Write-Host " [Current] AD Display Name: $($CurrentAdUserInfo.DisplayName)"
        Write-Host " [Current] AD EmployeeID: $($CurrentADUserInfo.SamAccountName)"
        Write-Host " [Current] AD First Name: $($CurrentADUserInfo.GivenName)"
        Write-Host " [Current] AD Last Name: $($CurrentADUserInfo.SurName)"
        Write-Host " [Current] AD Manager: $($CurrentADManagerInfo.Name)"
        Write-Host " [Current] AD ManagerID: $($CurrentADManagerInfo.SamAccountName)"
        Write-Host " [Current] AD Title: $($CurrentADUserInfo.Title)"
        Write-Host " [Current] AD New Hire Date (ExtensionAttribute2): $($CurrentADUserInfo.ExtensionAttribute2)"
        Write-Host " [Current] AD Position Code (ExtensionAttribute4): $($CurrentADUserInfo.ExtensionAttribute4)"
        Write-Host "Updating account for $($CheckAccount.'First Name') $($CheckAccount.'Last Name') with:" -ForeGroundcolor Yellow
        Write-Host " [New]Name: $($UpdateUser.DisplayName)" -ForegroundColor Cyan
        Write-Host " [New]EmployeeID: $($UpdateUser.EmployeeID)" -ForeGroundcolor Cyan
        Write-Host " [New]First Name: $($UpdateUser.FirstName)" -ForegroundColor Cyan
        Write-Host " [New]Last Name: $($UpdateUser.LastName)" -ForegroundColor Cyan
    
    ##Update Manager
        Try { 
            Set-AdUser -Identity $User -Manager $NewManagerInfo.SamAccountName -ErrorAction Stop
            Write-Host " [Updated] Manager: $($NewManagerInfo.Name)" -ForegroundColor Cyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [Updated] Manager: $($NewManagerInfo.Name)" | Out-File $logFileLocation -Append
            Write-Host " [Updated] ManagerID: $($NewManagerInfo.SamAccountName)" -ForeGroundcolor Cyan
            Write-Output "[$CurrentTime] [Updated] ManagerID: $($NewManagerInfo.SamAccountName)" | Out-File $logFileLocation -Append
        }
        Catch {
            Write-Host "[-] Failed to update manager field for $($UpdateUser.DisplayName)." -ForeGroundcolor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] Failed to update manager field for $($UpdateUser.Displayname)." | Out-File $logFileLocation -Append
        }
    
    ##Update Title
        Try {
            Set-AdUser -Identity $User -Title $UpdateUser.Title -ErrorAction Stop
            Write-Host " [Updated] Title: $($UpdateUser.Title)" -ForegroundColor Cyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [Updated] Title: $($UpdateUser.Title)" | Out-File $logFileLocation -Append
        }
        Catch {
            Write-host "[-] Failed to update Title field for $($UpdateUser.Displayname)." -ForeGroundcolor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] Failed to update Title field for $($UpdateUser.DisplayName)." | Out-File $logFileLocation -Append
        }

    ##Update Hire Date
        Try {
            Set-AdUser -Identity $user -Replace @{extensionAttribute2=$UpdateUser.HireDate} -ErrorAction Stop
            Write-Host " [Updated] New Hire Date: $($UpdateUser.HireDate)" -ForegroundColor Cyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [Updated] New Hire Date: $($UpdateUser.HireDate) " | Out-File $logFileLocation -Append
        }
        Catch {
            Write-Host "[-] Failed to update the Hire Date, ExtensionAttribute2, for $($UpdateUser.DisplayName)." -ForeGroundcolor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] Failed to update the hire date, ExtensionAttribute2, for $($UpdateUser.DisplayName)." | Out-File $logFileLocation -Append
        }
    
    ##Update Position Code
        Try {
            Set-AdUser -Identity $User -Replace @{extensionAttribute4=$UpdateUser.PositionCode} -ErrorAction Stop
            Write-Host " [Updated] Position Code: $($UpdateUser.PositionCode)" -ForeGroundcolor Cyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [Updated] Position Code: $($UpdateUser.PositionCode)" | Out-File $logFileLocation -Append
        }
        Catch {
            Write-Host "[-] Failed to update the Position Code, ExtensionAttribute4, for $($Updateuser.DisplayName)." -ForeGroundcolor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] Failed to update the Position Code, ExtensionAttribute4, for $($UpdateUser.DisplayName)." | Out-File $logFileLocation -Append
        }

        ##Update Location
        Try {
         Set-AdUser -Identity $User -Office $UpdateUser.Office
            Write-Host " [Updated] Office: $($UpdateUser.Office)" -ForeGroundcolor Cyan
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [Updated] Office: $($UpdateUser.Office)" | Out-File $logFileLocation -Append
        }
        Catch {
            Write-Host "[!] Failed to set the Office value imported from the CSV. Please check manually." -ForeGroundcolor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [!] Failed to set the Office value imported from CSV. Please check manually." | Out-File $logFileLocation -Append
        }

    ##Update Date that InfiniumToAD Ran
        Try {
            $CurrentTime = Get-Date
            Set-AdUser -Identity $user -Replace @{extensionAttribute5=$CurrentTime.ToString()} -ErrorAction Stop
            Write-Host " [++] Script updated $User's account at $CurrentTime." -ForeGroundcolor Cyan
            Write-Output "[$CurrentTime] [++] Script updated $user's account at $CurrentTime." | Out-File $logFileLocation -Append
        }
        Catch {
            Write-Host "[-] Failed to update ExtensionAttribute5, for $User." -ForeGroundcolor Red
            $CurrentTime = Get-Date
            Write-Output "[$CurrentTime] [-] Failed to update ExtensionAttribute5, for $User." | Out-File $logFileLocation -Append
        }

        ##Re-Enables account if it was previously disabled. Moves it to correct OU.
 <#      
        $ReEnableAccount = $CurrentADUserInfo
        if (($ReEnableAccount).Enabled -eq $False) {            
            ## Re-enables account 
            Try { 
                $CurrentTime = Get-Date
#DT             Set-AdUser -Identity $User -Enabled $True -Description "Re-Enabled by AS400 Feed on $CurrentTime."
                Write-Output "[$CurrentTime] [+] Re-Enabled account for $User." | Out-File $LogFileLocation -Append
                Write-Host "[+] Re-Enabled account for $User." -ForeGroundcolor Cyan
            }
            Catch {
                $CurrentTime = Get-Date
                Write-Host "[-] Failed to re-enable account for $User." -ForeGroundcolor Red
                Write-Output "[$CurrentTime] [-] Failed to re-enable account for $User." | Out-file $LogFileLocation -Append   
             }
            ## Moves Re-enabled account to Re-enabled OU.
            Try { 
#DT             Move-ADObject -Identity $ReEnableAccount.DistinguishedName -TargetPath "OU=Re-Enabled Accounts,OU=NewUsers,OU=People,OU=-Domain-,DC=private,DC=LAN" -ErrorAction Stop
                $CurrentTime = Get-Date
                Write-Output "[$CurrentTime] [+] Moved $User to 'Re-Enabled Accounts' OU." | Out-File $LogFileLocation -Append
                Write-Host "[+] Moved $User to 'OU=Re-Enabled Accounts,OU=NewUsers...'" -ForeGroundcolor Cyan
            }
            Catch {
                Write-Host "[-] Failed to move $User to correct OU." -ForeGroundcolor Red
                $CurrentTime = Get-Date
                Write-Host "[$CurrentTime] [-] Failed to move $User to correct OU." | Out-File $LogFileLocation -Append
            }
        } 

        ##Update Exempt/Nonexempt group
        if ($UpdateUser.Exempt -eq "N/EXP") {
            Write-Host " [New Group]: Non-Exempt Employees" -ForegroundColor Cyan
#DT               Add-ADGroupMember -Identity Non-ExemptEmp -Members $User -ErrorAction Stop
#DT               Remove-ADGroupMember -Identity ExemptEmp -Members $User -Confirm:$False -ErrorAction Stop
            } Else {
#DT               Add-ADGroupMember -Identity ExemptEmp -Members $User -ErrorAction Stop
#DT               Remove-ADGroupMember -Identity Non-ExemptEmp -Members $User -Confirm:$False -ErrorAction Stop
                Write-Host " [New Group]: Exempt Employees" -ForegroundColor Cyan
        }
        #>
    }
}

<# After accounts are created a manual sync from AD to o365 kicks off.  
#Try { Start-ADSync -ErrorAction Stop }
#Catch { Write-Host "[Error] Could not start AD Sync to o365." -ForegroundColor DarkCyan }
#>

##~> Removes PSSession to Office365.
Get-PSSession | Remove-PSSession

##~> Script Processing Metrics.
$EndTime = Get-Date
$ADProcess = ($Endtime - $adchecktime).TotalSeconds
$TimeToProcess = ($Endtime - $Starttime).TotalSeconds
Write-Output " " ; Write-Host " [ ADCheck completed running in $ADProcess seconds. ] " -ForegroundColor 'White' -BackgroundColor 'DarkRed' 
Write-Output " " ; Write-Host " [ Script completed running in $TimeToProcess seconds. ] " -ForegroundColor 'White' -BackgroundColor 'DarkRed'  

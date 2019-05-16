Import-Module -Name \\corp-archive1\SystemAdmins\PowerShell\Commands\Connect-SM_O365.ps1
$WarningPreference.value__ = 0

Function Start-SM_ADSync {
    $startTime = Get-Date -Format hh:mm:ss
    Write-Host "Creating PSSession to ADConnect." -ForegroundColor Yellow
    $ADConnect = New-PSSession -Name ADConnect -ComputerName ADConnect -EnableNetworkAccess
    Write-Host "Importing the ADSync Modules from the ADConnect PSSession." -ForegroundColor Yellow
    Import-PSSession -Session $ADConnect -Module ADSync -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | 
        Out-Null
    
    Write-Host "[$startTime] Starting AD Sync." -ForegroundColor Yellow
    Invoke-Command -Session $ADConnect -ScriptBlock {Start-ADSyncSyncCycle -PolicyType Delta} | Out-Null

    Start-Sleep -Seconds 2

    $SyncIsRunning = Get-AdSyncScheduler 
        While ($SyncIsRunning.SyncCycleInProgress -eq $True) {
            Write-Host " - ADSync is currently running." -ForegroundColor Cyan
            Start-Sleep -Seconds 5
            $SyncIsRunning = Get-AdSyncScheduler 
            }
    $endTime = Get-Date -Format hh:mm:ss
    Write-Host "[$endTime] AD Sync has completed running." -ForegroundColor DarkGreen
    Write-Output ''

    Remove-PSSession -Name ADConnect
}

Write-Host "Creating PSSession to Microsoft Exchange 2013." -ForegroundColor Yellow
$onPremExchange = New-PSSession -Name onPremExchange -ConfigurationName Microsoft.Exchange `
    -ConnectionUri http://Corp-EXCas1.SM.LAN/PowerShell -Authentication Kerberos
Import-PSSession $onPremExchange -AllowClobber -ErrorAction SilentlyContinue -WarningAction SilentlyContinue |
    Out-Null

#Store the data from ADUsers.csv in the $ADUsers variable
$newUsers = Import-Excel -Path "Y:\SystemAdmins\Estrada\Projects\ONB script\Test_Run.xlsx" 
$alreadyOnAD = [Ordered]@{}
$notinAD = [Ordered]@{}

#Loop through each row containing user details in the CSV file 
$Results = foreach ($User in $newUsers) {
    #Read user data from each field in each row and assign the data to a variable as below
    $Properties = [Ordered]@{
        'EmployeeID'  = $User.'EE#' ;
        'Password'  = $User.Password ;
        'FirstName' = $User.First ;
        'LastName'  = $User.Last ;
        'OU'        = "OU=ASM,OU=StoreUsers,OU=People,OU=-SaveMart-,DC=SM,DC=LAN" ;
        'Email'     = $User.First + '.' + $User.Last + '@Savemart.com';
        #'StreetAddress' = $User.StreetAddress ;
        'City'      = $User.City ;
        #'ZipCode'   = $User.ZipCode ;
        #'State'     = $User.State ;
        #'Country'   = $User.Country ;
        #'Telephone' = $User.Telephone ;
        'JobTitle'  = $User.Title ;
        #'Company'   = $User.Company ;
        #'Department' = $User.Store ;
    }
    $obj = New-Object -TypeName psobject -Property $Properties
    $obj

    Try { 
        Get-ADUser $obj.EmployeeID -ErrorAction stop | out-null
        $alreadyOnAD.add($obj.EmployeeID, 'Exists')
        } catch {
        Write-Output ''
        $CurrentTime = Get-Date -Format hh:mm:ss 
        Write-Host " [$CurrentTime] Cannot find active directory account for $($obj.Firstname) $($Obj.Lastname). EmployeeID: $($obj.employeeid)" -ForegroundColor DarkRed 
        $notInAD.add($Obj.EmployeeID, 'newUser')
        Write-Output ''
        }    
}

foreach ($newUser in $notinAD.Keys) {
    Write-Output ''
    $CurrentTime = Get-Date -Format hh:mm:ss
    Write-Host " [$CurrentTime] Creating account for $($obj.Firstname) $($Obj.Lastname). EmployeeID: $newUser." `
        -ForegroundColor DarkGreen
    $newUserInfo = $Results | Where EmployeeID -eq $newUser
    $UPN = "$($newUserInfo.EmployeeID)@Savemart.com"
    $newDisplayName = $NewUserInfo.FirstName + ' ' + $NewUserInfo.LastName
    #User does not exist then proceed to create the new user account                     
    #Account will be created in the OU provided by the $OU variable read from the CSV file
    New-ADUser -SamAccountName $newUserInfo.EmployeeID `
                -UserPrincipalName $UPN `
                -Name $newDisplayName `
                -GivenName $newUserInfo.FirstName `
                -Surname $newUserInfo.LastName `
                -Enabled $True `
                -DisplayName "$newDisplayName" `
                -Path "$($newUserInfo.OU)" `
                -City $City `
                -Company $Company `
                -State $State `
                -StreetAddress $streetAddress `
                -OfficePhone $Telephone `
                -EmailAddress $newUserInfo.Email `
                -Title $newUserInfo.JobTitle `
                -Department $Department `
                -AccountPassword (ConvertTo-SecureString $newUserInfo.Password -AsPlainText -Force) -ChangePasswordAtLogon $True
    
    Start-Sleep -Seconds 3
    Enable-Mailbox -Identity $UPN | Out-Null
    Enable-Mailbox -Identity $UPN -Archive
}

Remove-PSSession $onPremExchange | Out-Null
Write-Output ''

Start-Sleep 3
Start-SM_ADSync
Write-Host "Please wait while verifying users are now synced to AAD."
Start-Sleep -Seconds 90

Write-Host "Gathering SM Lan Credentials." -ForegroundColor Cyan
$onPremCred = Get-Credential -Message "Enter your SM Credentials. Example: SM\Employeeid" -UserName SM\91037 

Connect-SM_O365
Start-Sleep 3

$ReadytoAddLicense = [Ordered]@{}

Foreach ($migratedUserID in $notinAD.keys) {
    $runCount = [int]0
    Write-Host " Starting to work on [ $migratedUserID ]" -ForegroundColor DarkGreen
    $UserMigrated = $False
    While ($UserMigrated -eq $false) {
        Try {
            $Verify_MigratedSuccessfully = Get-User $migratedUserID -ErrorAction Stop 
            if ($Verify_MigratedSuccessfully.RecipientType -eq 'MailUser') {
                $CurrentTime = Get-Date -Format hh:mm:ss
                Write-Host "Verified that $migratedUserID was successfully synced to o365.. Migrating mailbox over."

                $EmailToMigrate = ($Results | where employeeiD -eq $migratedUserID).email
                Write-Host "Migrating $EmailToMigrate." -ForegroundColor Cyan

                New-MoveRequest -Identity "$emailToMigrate" -Remote -TargetDeliveryDomain 'SaveMartsupermarkets.mail.onmicrosoft.com' `
                -RemoteHostName 'Webmail.SaveMart.com' -RemoteCredential $onPremCred -BadItemLimit 1000 `
                -LargeItemLimit unlimited –AcceptLargeDataLoss -ErrorAction SilentlyContinue |
                Out-null

                $UserMigrated = $True
                $ReadytoAddLicense.add("$MigratedUserID","Ready for License")
                }
            } Catch {
                $CurrentTime = Get-Date -Format hh:mm:ss
                Write-Host "[$CurrentTime] Cannot Verify Account that the account for $MigratedUserID was migrated. Checking Again." -ForegroundColor DarkCyan
                Start-Sleep -Seconds 30
                $runCount += 1
                if ($runCount -eq 4) { 
                    Start-SM_ADSync
                    }
                }
    }
}

foreach ($NeedsLicense in $ReadytoAddLicense.keys) {
    $MoveRequestComplete = Get-Moverequest -Identity $NeedsLicense
    
    While ($MoveRequestComplete.Status -ne 'Completed') {
        $CurrentTime = Get-Date -Format hh:mm:ss
        Write-Host "[$CurrentTime] Waiting for mailbox to finish migrating" -ForegroundColor Cyan
        Start-Sleep -Seconds 25
        $MoveRequestComplete = Get-Moverequest -Identity $NeedsLicense
        }
    if ($MoveRequestComplete.status -eq 'Completed') {
        $CurrentTime = Get-Date -Format hh:mm:ss
        Write-Host "[$CurrentTime] Mailbox Migration for $NeedsLicense is complete!" -ForegroundColor Green
        $CurrentTime = Get-Date -Format hh:mm:ss
        Write-Host "[$CurrentTime] Adding F1 License." -ForegroundColor Cyan
        Add-ADGroupMember -Identity 'Office365-F1-Store-ASM' -Members $migratedUserID
        }
}

$WarningPreference.value__ = 2

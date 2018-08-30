function Get-HDCSDiags.ps1 {
    Begin {
        $DStoreNumber = Read-host -Prompt 'What is the 3 digit store number?'
        $DRegisterNumber = Read-Host -Prompt 'What is the two digit register number?'
        $DRegisterLogin = Read-Host -Prompt 'What is the register user account?'
        $DRegisterPW = Read-Host -Prompt 'What is the register user account password?'
        $DHostName = 'store0'+$DStoreNumber+'pos0'+$DRegisterNumber
        # Maps register's c: drive to the POS server as H: #
        new-psdrive -Name H -PSProvider FileSystem -Root \\$DHostName\C$ -Credential $DRegisterLogin -Scope Script
        # If the register's drive was not mapped succesfully it will set the variable $DriveMapped to False.
        if(!(test-path -Path h:)) {
            write-host "Unable to map to register's drive."
            $DriveMapped = $false
            }
        # If the register's drive is mapped successfully it will remove the ACSDiagFile.ini from H:\ACS\Diag\ACSDiagFile.ini
        else { 
            Write-Host "The H: drive was loaded successfully" -ForegroundColor DarkGreen
            Write-Host " "
            Remove-Item H:\ACS\Diag\ACSDiagFile.ini -Force -Verbose
            }
        # If the folder cannot find C:\HDTools\ it will create the folder by copying the files from Y:\HD\App\HDTools
        if (!(test-path -Path C:\HDTools\))  {
            Write-Host "Could not find the folder C:\HDTools. Creating the folder now." -ForegroundColor Yellow
            Write-Host " "
            New-Item -Path C:\HDTools -ItemType Directory ;
            Copy-Item -path Y:\HD\App\HDTools\* -destination C:\HDTools\ -recurse
            Write-Host " "
            Write-Host "Copied folders Y:\HD\App\HDTools to C:\HDTools\" -ForegroundColor Yellow
            Write-Host " "
        }
    }
    Process { 
        # If the drive was not successfully mapped it will stop this from processing any further
        if ($DriveMapped -eq $false) {Pause; break}
        else {
        # If the register's drive was mapped sucessfully it will copy the ACSDiagFile.ini from C:\HDTools\PSTools
        # to replace the .ini file in the register.
            Copy-Item C:\HDTools\PsTools\ACSDiagFile.ini -Destination H:\ACS\diag\ -Verbose
        # This uses PSExec from C:\HDTools\PSTools to connect to the register and launch C:\ACS\Diag\ACSLogs.cmd
            invoke-command { 
            & 'C:\HDTools\PsTools\PsExec.exe' \\$DHostName -u $DRegisterLogin -p $DRegisterPW `
            C:\acs\diag\ACSLogs.cmd } -verbose
        }
    }
    End {
        if ($DriveMapped -eq $false) {Write-host 'Unable to map to register drive'}
        else { 
        # This next step checks that the folder C:\RegisterDiags\ is created. If it is not, the folder will be created.
            Write-Host " "
            Write-Host "Copying diagnostic files from register to POS Server." -ForegroundColor Yellow
            Write-Host " "
            if (!(test-path -Path C:\RegisterDiags\)) {
                Write-Host "Could not find the folder C:\RegisterDiags. Creating the folder now." -ForegroundColor Yellow
                Write-Host " "
                New-Item -ItemType Directory -path "C:\RegisterDiags" -WarningAction SilentlyContinue
                if (test-path -path C:\RegisterDiags\) {
                    Write-Host "C:\RegisterDiags was successfully Created." -ForegroundColor Green
                    }
                }
        # This copies the diag zip file from the mapped register drive to the C:\RegisterDiags folder on the POS Server.
            Copy-Item H:\ACS\Diag\*.zip -Destination C:\RegisterDiags\ -Verbose
            Write-Host " "
            Write-Host "Diagnostic files have been copied. Unmounting register drive." -ForgroundColor Yellow
            Write-Host " "
        # This deletes the zip files that were in the register's ACS\Diag folder and unmounts the mapped drive.
            Remove-Item H:\ACS\diag\*.zip 
            Remove-PsDrive -Name H
            Net Use \\$DHostName\c$ /delete
            Write-Host "Register mapped drive has been unmounted." -ForegroundColor Yellow
            Write-host " "
            Write-Host "The diagnostic file was successfully copied from the register to the POS Server." -ForegroundColor DarkGreen
            Write-Host "The file is located in the C:\RegisterDiags. Add the location and name to your" -ForegroundColor DarkGreen
            Write-Host "BOSS Support Central Ticket." -ForegroundColor DarkGreen
            Write-Host " " 
            Write-Host " "
            Pause
        }
    }
}
Get-HDCSDiags.ps1


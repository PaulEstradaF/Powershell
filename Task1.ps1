$Computers = Get-Content C:\Powershell\Store0726pos_Registers.txt
$Creds1 = Get-Credential -Credential Creds1
$Creds2 = Get-Credential -Credential Creds2

foreach ($Computer in $Computers) {
    Write-Host " Working with $Computer." -ForegroundColor Blue -BackgroundColor Yellow
    Write-Output ""
    
    if ($Computer -like 'CompLoc*D'){
        Write-Host "  This is a Computer." -BackgroundColor White -ForegroundColor DarkRed
        $Creds = $Creds2
    } else {
        Write-Host " This is a Laptop." -BackgroundColor White -ForegroundColor Blue
        $Creds = $Creds1
        }

    New-PSDrive -Name H -Root \\$Computer\c$ -PSProvider FileSystem -Credential $Creds -OutVariable hDriveMapped | Out-Null
    if ($hDriveMapped.root -eq "\\$Register\c$") {
            Write-Host " $Computer's drive was mapped successfully" -ForegroundColor Green
        }
<#
    Dir 'H:\Program files\Folder\SubFolder' | Where Name -eq File1 | Remove-Item
    Dir 'H:\Program files\Folder\SubFolder' | Where Name -eq File2 | Remove-Item
#>      
    # removing drive
    Write-Host "  Removing the mapped drive." -ForegroundColor Yellow
    Remove-PSDrive H -Force
    
}

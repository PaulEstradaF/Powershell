$Users = Import-Excel -Path C:\sharedFolder\file.xlsx

foreach ($user in $users) {
    $Password = $user.password 
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $UPN = $user.username + '@Lan'

    Write-Host " starting account creating."

    New-ADUser -SamAccountName $user.username `
               -Path $user.path `
               -AccountPassword $SecurePassword `
               -Name $user.username `
               -GivenName $user.username `
               -UserPrincipalName $upn `
               -Enabled $True `
               -DisplayName $user.Username 
    
    Add-ADGroupMember -Identity 'aDGroup' -Members $user.Username
}

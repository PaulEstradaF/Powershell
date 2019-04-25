$Users = Import-Excel -Path C:\MSAShared\KronosUsers.xlsx

foreach ($user in $users) {
    $Password = $user.password 
    $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
    $UPN = $user.username + '@SM.Lan'

    Write-Host " starting account creating."

    New-ADUser -SamAccountName $user.username `
               -Path $user.path `
               -AccountPassword $SecurePassword `
               -Name $user.username `
               -GivenName $user.username `
               -UserPrincipalName $upn `
               -Enabled $True `
               -DisplayName $user.Username 
    
    Add-ADGroupMember -Identity 'win10essbase' -Members $user.Username
    #Set-ADAccountPassword -NewPassword $SecurePassword -Server Corp-DC1.SM.Lan 

}

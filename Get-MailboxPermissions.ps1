Function Get-MailboxPermissions {
    [cmdletbinding()]
    Param (
    [parameter(mandatory=$True)][String[]]$EmailAddresses
    )
    
    Foreach ($EmailAddress in $EmailAddresses) {    
        $Users = Get-MailboxPermission $EmailAddress | Where User -like "*@domain.com"

        Foreach ($User in $Users) {
            $UserADInfo = (Get-ADUser -Identity $User.user.Trimend('@domain.com') -Properties *)
            $Props = [ordered]@{
                EmployeeID = $UserADInfo.SamAccountName
                User = $UserADInfo.Name
                AccessRights = $user.AccessRights
                } # End of Props
            $Obj = New-Object -TypeName psobject -Property $props
            $Obj


            } # End of Foreach Users              
        }  
} # End of Foreach Loop

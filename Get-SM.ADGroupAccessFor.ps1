Function Get-SM.ADGroupAccessFor {
    [cmdletbinding()]
    Param(
    [Parameter(Mandatory=$True)][String[]]$Users
    )

    Foreach ($User in $Users) {
        $UserInfo = Get-aduser $User -Properties *
        Foreach ($Group in $Userinfo.Memberof) {
            $Props = [Ordered]@{
                DistinguishedName = $UserInfo.CanonicalName
                EmployeeID = $UserInfo.SamAccountName
                Name = $UserInfo.DisplayName
                GroupCanonicalName = (Get-ADGroup -Identity $Group -Properties *).CanonicalName
                GroupName = (Get-ADGroup -Identity $Group).Name
                GroupDescription = (Get-ADGroup -Identity $Group -Properties *).Description
                } #End of props
            $Obj = New-Object -TypeName PSObject -Property $Props
            $Obj
        } #End of Foreach
    } # End of Foreach
} # End of Function

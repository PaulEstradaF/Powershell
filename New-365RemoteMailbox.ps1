Function New-O365RemoteMailbox {
    [cmdletbinding()]
    Param(
    [Parameter()]$EmployeeID
    )

    Enable-RemoteMailbox -identity $EmployeeID -RemoteRoutingAddress "$EmployeeID@OrgName.mail.onmicrosoft.com"
    Set-RemoteMailbox $EmployeeID
}

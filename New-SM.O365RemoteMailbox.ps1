Function New-SM.O365RemoteMailbox {
    [cmdletbinding()]
    Param(
    [Parameter()]$EmployeeID
    )

    Enable-RemoteMailbox -identity $EmployeeID -RemoteRoutingAddress "$EmployeeID@savemartsupermarkets.mail.onmicrosoft.com"
    Set-RemoteMailbox $EmployeeID
}

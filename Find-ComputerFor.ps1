Function Find-ComputerFor {
    [CmdletBinding()]
    Param (
    [ValidateSet("EmployeeID", "EmployeeName")]
    [Parameter(Mandatory=$True,
               HelpMessage="Enter the user's employee id.")]
    [String]$SearchBy,

    [Parameter(Mandatory=$False)]
    [String]$EmployeeID, 

    [Parameter(Mandatory=$False)]
    [String]$EmployeeName

    )
      
        if($SearchBy -eq "EmployeeID") {
            $IDDN = Get-ADUser -Identity $EmployeeID -Properties * | Select -ExpandProperty DisplayName

            Get-ADComputer -Filter "Description -Like '*$IDDN*'" -Properties * |
            Select Description, DNSHostName, DistinguishedName, IPv4Address, msDS-AuthenticatedAtDC, LastLogonDate 
        }

        if ($Searchby -eq 'EmployeeName') {
            Get-AdComputer -Filter "Description -like '*$EmployeeName*'" -Properties * |
            Select Description, DNSHostname, DistingushedName, Ipv4Address, msDS-AuthenticatedatDC, LastlogonDate
        }


}

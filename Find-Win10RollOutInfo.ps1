Function Find-Win10RollOutInfo {
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
            $IDDN = Get-ADUser -Identity $EmployeeID -Properties * 
            Get-ADComputer -Filter "Description -Like '*$($IDDN.Displayname)*'" -Properties * |
            Select Description, Name, DistinguishedName, IPv4Address, msDS-AuthenticatedAtDC, LastLogonDate -outvariable adcomputer | out-null
			
            foreach ($computer in $adcomputer.name) {
	    	Get-ADComputer -identity $computer -Properties * |
 		Select Description, Name, DistinguishedName, IPv4Address, msDS-AuthenticatedAtDC, LastLogonDate -outvariable adcomputer2  | out-null
			
		$props = @{'Name'="$($IDDN.displayname)";
			   'Department'="$($iddn.department)";
			   'ComputerName'=$($adcomputer2.Name);
			   'IPAddress'=$($adcomputer2.IPv4Address);
			   'Description'=$($adcomputer2.description);
	        }
		$obj = New-Object -TypeName psobject -property $props
		Write-output $obj
	     }
        }

        if ($Searchby -eq 'EmployeeName') {
            Get-AdComputer -Filter "Description -like '*$EmployeeName*'" -Properties * |
            Select Description, DNSHostname, DistingushedName, Ipv4Address, msDS-AuthenticatedatDC, LastlogonDate
        }


}

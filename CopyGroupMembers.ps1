 Param(
[Parameter(Mandatory=$true)][string]$SourceGroup,
[Parameter(Mandatory=$true)][string]$DestinationGroup
)
Start-Transcript "$PSScriptRoot\temp\CopyADGroupMembers.txt"
#Enter the source group name
$SourceGroupMembers = Get-ADGroupMember -Identity "$SourceGroup"
#Enter the destination group name
$DestinationGroupMembers = Get-ADGroupMember -Identity "$DestinationGroup"
#Loop through each member in the source group
$SourceCount = Get-ADGroupMember -Identity $SourceGroup | Measure-Object | Select Count
$DestinationCount = Get-ADGroupMember -Identity $DestinationGroup | Measure-Object | Select Count
Foreach($SourceGroupMember in $SourceGroupMembers)
{
    #Check if the user exists in the destination group or not
    If($DestinationGroupMembers.SamAccountName -match $SourceGroupMember.SamAccountName)
    {
        #Do nothing, the user exists
    }
    Else
    {
        #Add the user to the destination group
        Write-Host ("Adding {0} to group $DestinationGroup" -f $SourceGroupMember.SamAccountName )
        Add-ADGroupMember -Identity $DestinationGroup -Members $SourceGroupMember.SamAccountName
    }
}
$DestinationNewCount = Get-ADGroupMember -Identity $DestinationGroup | Measure-Object | Select Count
Write-Host "Added $($SourceCount.count) Users to $DestinationGroup"
Write-Host "$DestinationGroup old count: $($DestinationCount.count)"
Write-host "$DestinationGroup new count: $($DestinationNewCount.count)"
Stop-Transcript 

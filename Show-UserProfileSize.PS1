Function Show-UserProfileSize {
    [CmdletBinding()]
    Param(
    [Parameter(Mandatory=$True)]$UserName,
    [Switch]$ShowTotalProfileSize
    )

    $RootFolders = Get-ChildItem -Path c:\users\$Username  -Force | Where Mode -Like 'D*'
    $RootFolderFiles = Get-ChildItem -Path c:\users\$Username  -Force | Where Mode -notLike 'D*' 

    $Results = Foreach ($Folder in $RootFolders){
        $CurrentFolderFiles = Get-ChildItem -Path $Folder.Fullname -Recurse -Force -ErrorAction SilentlyContinue| 
            Where Mode -NotLike 'D*'
        $FolderSize = ($CurrentFolderFiles | Measure -Sum Length).Sum / 1mb

        $Props = [Ordered]@{
            'Folder Name' = $Folder.Name;
            'Folder Size (MB)' = [math]::Round($FolderSize)
        }
    
        $obj = New-Object -TypeName psobject -Property $Props
        $obj
        }

    #This displays the folders next to their total folder size
    $Results
    Write-Output ""

    #This will find the total size
    if ($ShowTotalProfileSize) {
        
        $RawProfileSize = ($Results | Measure -Sum 'Folder Size (MB)').Sum * 1MB
        Write-Output "The total size of the local profile for $UserName is $($RawprofileSize /1mb) MB."
        }
    }
     

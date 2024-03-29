$un = Read-Host -prompt "What is your domain Account?"
$fd = Read-Host -prompt "From Date"
$td = Read-Host -Prompt "To Date'"
(Get-Content C:\Users\$un\Desktop\ZenDesk\Export.json) | ConvertFrom-Json | 
Select Subject, Description -Expand Comments | 
Select Ticket_ID, Subject, Description, Body, Created_At |
where {$_.Created_at -gt $fd -and $_.created_at -lt $td} | 
export-csv -Path c:\users\$un\desktop\ZenDesk\ExportedTickets.csv

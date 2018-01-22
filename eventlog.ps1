# event log viewing, filtering and sorting

Get-EventLog -List
Get-EventLog -LogName "Application" -Newest 10
Get-EventLog -LogName "Application" | Where-Object { $_.InstanceID -like 666 }
Get-EventLog -LogName "Application" | Where-Object { $_.EntryType -eq "Error" -or $_.EntryType -eq 'Warning' } #Error|Warning|Information
Get-EventLog -LogName "Application" | Sort-Object "Source" -unique
Get-EventLog -LogName "System" -ComputerName "RemoteServer" -Newest 10 

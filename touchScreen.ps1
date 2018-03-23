# Disable/enable touch screen 

Get-PnpDevice | Where-Object {$_.FriendlyName -like '*touch screen*'} | Disable-PnpDevice -Confirm:$False

Get-PnpDevice | Where-Object {$_.FriendlyName -like '*touch screen*'} | Enable-PnpDevice -Confirm:$False

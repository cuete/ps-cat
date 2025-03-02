$wifiAdapter = Get-NetAdapter | Where-Object {$_.Name -like "*Wi-Fi*"}
$defaultGateway = Get-NetIPConfiguration -InterfaceIndex $wifiAdapter.InterfaceIndex | Select-Object -ExpandProperty IPv4DefaultGateway 
Start-Process "http://$($defaultGateway.NextHop)"
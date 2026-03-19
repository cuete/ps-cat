Param ([switch]$speedtest=$false)

$conn = Test-Connection -TargetName bing.com -Count 1 -TimeoutSeconds 2 | Select-Object Status, Latency
if($conn.Status -ne "Success") {
    Write-Host "Connection status: $($conn.Status) ($($conn.Latency)ms)`n" -ForegroundColor $fcolor_err
}
else {
    Write-Host "Connection status: $($conn.Status) ($($conn.Latency)ms)`n" -ForegroundColor $fcolor
    $ip = Invoke-WebRequest https://api.ipify.org?format=json | Select-Object -ExpandProperty Content | ConvertFrom-Json
    Write-Host "My IP address is $($ip.ip)`n" -ForegroundColor $fcolor
    if($speedtest)
    {
        Write-Host "Testing connection speed...`n" -ForegroundColor $fcolor
        Invoke-Expression "python C:\python310\lib\site-packages\speedtest.py --single --simple"
    }
}
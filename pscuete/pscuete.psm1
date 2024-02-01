# cuete's personal powershell module

# Reboots the computer now
function Restart-Compu
{
    shutdown.exe /r /t 0
}
Export-ModuleMember -Function Restart-Compu

# Sleeps the computer now
function Suspend-Compu
{
    rundll32.exe powrprof.dll, SetSuspendState Sleep
}
Export-ModuleMember -Function Suspend-Compu

# Shows current local, UTC and epoch times
function Show-TimeDate
{
    $date = Get-Date
    $utcdate = $date.ToUniversalTime()
    $posixdate = Get-Date -UFormat %s

    Write-Host Local Time: $date -ForegroundColor $fcolor
    Write-Host UTC Time: $utcdate  -ForegroundColor $fcolor
    Write-Host Epoch: $posixdate`n  -ForegroundColor $fcolor
}
Export-ModuleMember -Function Show-TimeDate

# Shows computer processor, memory and battery stats
function Show-MachineStats
{
    $proc = Get-CimInstance CIM_Processor |  Select-Object -ExpandProperty LoadPercentage
    $mem = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty FreePhysicalMemory
    $batt = (Get-WmiObject win32_battery).estimatedChargeRemaining
    Write-Host Processor usage: ($proc)% -ForegroundColor $fcolor
    Write-Host Free Memory: ($mem/1000000) Gb  -ForegroundColor $fcolor
    Write-Host Battery remaining: ($batt)%`n  -ForegroundColor $fcolor
}
Export-ModuleMember -Function Show-MachineStats

# Queries the NOAA's weather API (https://www.weather.gov/documentation/services-web-api)
# in all location listed on weatherlocations.json
# Location query by city name needs Bing Maps API Key
function Show-Weather {
    Param (
        [switch]$h = $false,
        [string]$l)

    $headers = @{
        "Accept" = "application/geo+json"
        "User-Agent" = "(appid, email@email.com)" # Update this info, it identifies you to the API
    }

    $locationdata =  [PSCustomObject]@{
        locations =  [PSCustomObject]@()
    }

    if($l) # Resquested location
    {
        $BingMapsKey = '' # Your Bing Maps API Key
        $LocationQuery = $l

        $uri = "http://dev.virtualearth.net/REST/v1/Locations?query=$($LocationQuery)&key=$($BingMapsKey)"
        $response = Invoke-RestMethod -Method Get -Uri $uri
        $lat = $response.resourceSets.resources.point.coordinates[0]
        $lon = $response.resourceSets.resources.point.coordinates[1]

        $url = $url = "https://api.weather.gov/points/$($lat),$($lon)"
        $weather = Invoke-RestMethod -Uri $url -Method Get -Headers $headers

        $locationData.locations += [PSCustomObject]@{
            name = $LocationQuery
            lat = $lat
            lon = $lon
            gridx = $weather.properties.gridx
            gridy = $weather.properties.gridy
            office = $weather.properties.gridid
        }

    }
    else # Default locations
    {
        $locationData = Get-Content "weatherlocations.json" | Out-String | ConvertFrom-Json
    }
    
$endpoint = "forecast"
if($h)
{
    $endpoint += "/hourly"
}

$weathers = @()

foreach($location in $locationData.locations)
{
    $office = $location.office
    $gridx = $location.gridx
    $gridy = $location.gridy

    $url = "https://api.weather.gov/gridpoints/$office/$gridx,$gridy/$endpoint"
    $weather = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    
    $w = $weather.properties.periods[0]
    $weatherObject = [PSCustomObject]@{
        location = $location.name
        when = $w.name
        sTime = [DateTime]$w.startTime
        eTime = [DateTime]$w.endTime
        tF = $w.temperature
        tC = [int][math]::Round(($w.temperature - 32) * 5 / 9, 0)
        hum = $w.relativeHumidity.value
        prec = $w.probabilityOfPrecipitation.value
        windS = $w.windSpeed
        windD = $w.windDirection
        shortF = $w.shortForecast
        detailedForecast = $w.detailedForecast
    }
    $weathers += $weatherObject
}

Write-Host "`n $($weathers[0].sTime) - $($weathers[0].eTime)"

if($h)
{
    $weathers.startTime
    $weathers | Select-Object -Property location, tC, hum, prec, windS, windD, shortF | Format-Table -Wrap -AutoSize
}
else
{
    $weathers | Select-Object -Property location, when, tC, hum, prec, windS, windD, shortF, detailedForecast | Format-Table -Wrap -AutoSize
}
}
Export-ModuleMember -Function Show-Weather

# Tests internet connection and displays IP address
# Optionally runs speedtest using the speedtest python module https://pypi.org/project/speedtest-cli/
function Get-Ip {
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
}
Export-ModuleMember -Function Get-Ip

# Finds a sgtring in a file or directory name
# Optionally searches within files
function Find-Text
{
    Param (
        [string]$path,
        [string]$filter,
        [string]$text,
        [switch]$e = $false #extended - within file text
        )
    Write-Host "Usage: find -text {text} -path {path} -filter {filter}" -ForegroundColor $fcolor
    if($path -eq $null -or $path -eq "")
    {
        $path = Get-Location | Select-Object -ExpandProperty Path
    }

    #Directory names first
    Write-Host "Searching directory names..." -ForegroundColor $fcolor
    Get-ChildItem $path -Recurse -Directory -Filter "*$($text)*" | Select-Object Name | Format-Table -AutoSize $_.Value
    #| Where-Object {$_.Name -like "*$($text)*"} 

    #File names second
    Write-Host "Searching file names..." -ForegroundColor $fcolor
    Get-ChildItem $path -Recurse -File -Filter "*$($text)*"  -Exclude *.exe,*.dll | Select-Object Name | Format-Table -AutoSize $_.Value

    if ($e)
    {
        #File text third
        Write-Host "Searching file contents..." -ForegroundColor $fcolor
        Get-ChildItem $path -Recurse -Filter $filter -Exclude *.exe,*.dll | Select-String $text | Select-Object Path,Linenumber,Line | Format-Table -AutoSize $_.Value
    }
}
Export-ModuleMember -Function Find-Text

# Queries the Bing API
# Optionally selects a news filter
function Search-Bing
{
    Param (
    [Parameter(Mandatory=$true)]
    [Alias('q')]
    [string]$query,
    [Parameter(Mandatory=$false)]
    [switch]$news=$false,
    [Parameter(Mandatory=$false)]
    [int]$answercount = 3
    )

    $bingEndpoint = "" #Need to create a Bing API resource on Azure
    $apiKey = "" #Insert your API Key
    $lang = "en-US"
    $filter = "computation,entities"

    if ($news)
    {
        $filter = "news"
    }

    $uri = $bingEndpoint + "?q=$query&filter=$filter&answerCount=$answercount&safeSearch=off&promote=$filter"

    # Write-Host $uri

    $headers = @{
        'Ocp-Apim-Subscription-Key' = $apiKey
        "Accept-Language" = $lang
        "Accept" = "application/json"
    }

    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers

    $results = $response.webPages.value | Select-Object -First $answercount -Property name, snippet, url
    foreach ($result in $results)
    {
        $result | Select-Object -Property name, snippet | Format-List
    }
}
Export-ModuleMember -Function Search-Bing

# Acts as a virtual clipboard for files in conjunction with Paste-File
# copies the file path to a global variable (string list) acting as a stack
# Use Paste-File to paste the file in a new path
function Copy-File
{
    Param (
        [Parameter()]
        [Alias('f')]
        [string]$filename
    )

    if($filename -like '.\*')
    {
        $filename = $filename.TrimStart('.\')
    }

    if(!$global:fileList)
    {
        [Collections.Generic.List[String]]$global:fileList = @()
    }
    $sourcePath = Get-Location | Select-Object -ExpandProperty  Path
    $global:fileList += $sourcePath + '\' + $filename

    Write-Host "Added to clipboard, stack is: "
    foreach ($file in $global:fileList)
    {
        Write-Host "`t$($file)"
    }
}
Export-ModuleMember -Function Copy-File

# Acts as a virtual clipboard for files in conjunction with Copy-File
# pastes the file referenced at the top of the stack of the global variable (string list) into the current directory
# Use Copy-File to copy the source file path
function Write-File
{
    Param (
        [Parameter()]
        [Alias('k')]
        [switch]$keep = $false
    )

    if (Test-Path variable:global:fileArray && $global:fileList)
    {
        $fileData = $global:fileList[0].split('\')
        $destinationPath = Get-Location | Select-Object -ExpandProperty  Path
        $destinationFile = $destinationPath + '\' + $fileData[$fileData.Length -1]

        Write-Host "Pasting`n`tFrom:`t$($global:fileList[0])"
        Write-Host "`tTo:`t$($destinationPath + '\' + $fileData[$fileData.Length -1])"
        if(!(Test-Path $destinationFile))
        {
            Copy-Item -Path $global:fileList[0] -Destination ($destinationFile)
        }

        if(!$keep)
        {
            $global:fileList.RemoveAt(0)
        }
    }
}
Export-ModuleMember -Function Write-File

# Changes the display scale of the system
# The follwing values might change depending on the specific display's resolution, since '0' is the recommended scale for a given display:
# 0 = 100% (default or recommended)
# 1 = 125% 
# 2 = 150%... etc.
function Set-DisplayScale
{
    Param($s=0)
    $source = @'
    [DllImport("user32.dll", EntryPoint = "SystemParametersInfo")]
    public static extern bool SystemParametersInfo(
                      uint uiAction,
                      uint uiParam,
                      uint pvParam,
                      uint fWinIni);
'@
    $apicall = Add-Type -MemberDefinition $source -Name WinAPICall -Namespace SystemParamInfo -PassThru
    $apicall::SystemParametersInfo(0x009F, $s, $null, 1) | Out-Null
}
Export-ModuleMember -Function Set-DisplayScale

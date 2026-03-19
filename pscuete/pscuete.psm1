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
        [switch]$h = $false)

    $headers = @{
        "Accept" = "application/geo+json"
        "User-Agent" = "(appid, email@email.com)" # Update this info, it identifies you to the API
    }

    $locationdata =  [PSCustomObject]@{
        locations =  [PSCustomObject]@()
    }

    $locationData = Get-Content "weatherlocations.json" | Out-String | ConvertFrom-Json
    
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

# Displays WiFi connection status and default gateway
# Tests internet connection and displays IP address
# Optionally runs speedtest using the speedtest python module https://pypi.org/project/speedtest-cli/
function Get-Ip {
    Param ([switch]$speedtest=$false)

    $wifiAdapter = Get-NetAdapter | Where-Object {$_.Name -like "*Wi-Fi*"}
    $defaultGateway = Get-NetIPConfiguration -InterfaceIndex $wifiAdapter.InterfaceIndex | Select-Object -ExpandProperty IPv4DefaultGateway | Select-Object -ExpandProperty NextHop
    Write-Host "Default Gateway: http://$defaultGateway`n" -ForegroundColor $fcolor

    $conn = Test-Connection -TargetName bing.com -Count 1 -TimeoutSeconds 2 | Select-Object Status, Latency
    if($conn.Status -ne "Success") {
        Write-Host "Connection status: $($conn.Status) ($($conn.Latency)ms)`n" -ForegroundColor $fcolor_err
        ipconfig /all | Select-String "IPv4 Address" | ForEach-Object { $_.ToString().Split(":")[1].Trim() } | ForEach-Object { Write-Host "IPv4 $_" -ForegroundColor $fcolor_err }
    }
    else {
        Write-Host "Connection status: $($conn.Status) ($($conn.Latency)ms)`n" -ForegroundColor $fcolor
        $ipv46 = Invoke-WebRequest https://api64.ipify.org?format=json | Select-Object -ExpandProperty Content | ConvertFrom-Json
        Write-Host "IP $($ipv46.ip)`n" -ForegroundColor $fcolor
        if($speedtest)
        {
            Write-Host "Testing connection speed...`n" -ForegroundColor $fcolor
            # Speed test script from https://github.com/sivel/speedtest-cli
            Invoke-Expression "python <path to script>\speedtest.py --single --simple"
        }
    }
}
Export-ModuleMember -Function Get-Ip

# Finds a string in file/directory names and optionally within file contents
function Find-Text
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Text,
        [Parameter(Position=1)]
        [string]$Path = (Get-Location).Path,
        [string]$Filter = "*",
        [Alias('e', 'Extended')]
        [switch]$SearchContent = $false
    )

    # Validate path exists
    if (-not (Test-Path $Path)) {
        Write-Error "Path '$Path' does not exist."
        return
    }

    # Define common exclusions
    $excludedExtensions = @('*.exe', '*.dll', '*.bin', '*.obj', '*.pdb')

    try {
        # Search directory names
        Write-Host "Searching directory names for '$Text'..." -ForegroundColor $fcolor
        $directoriesFound = $false
        Get-ChildItem $Path -Recurse -Directory -Filter "*$Text*" -ErrorAction SilentlyContinue | ForEach-Object {
            $directoriesFound = $true
            Write-Host "Directory: $($_.Name) - $($_.FullName)" -ForegroundColor $fcolor
        }
        if (-not $directoriesFound) {
            Write-Host "No directories found." -ForegroundColor Yellow
        }

        # Search file names
        Write-Host "Searching file names for '$Text'..." -ForegroundColor $fcolor
        $filesFound = $false
        Get-ChildItem $Path -Recurse -File -Filter "*$Text*" -Exclude $excludedExtensions -ErrorAction SilentlyContinue | ForEach-Object {
            $filesFound = $true
            Write-Host "File: $($_.Name) - $($_.FullName)" -ForegroundColor $fcolor
        }
        if (-not $filesFound) {
            Write-Host "No files found." -ForegroundColor Yellow
        }

        # Search file contents if requested
        if ($SearchContent) {
            Write-Host "Searching file contents for '$Text'..." -ForegroundColor $fcolor
            $contentMatchesFound = $false
            Get-ChildItem $Path -Recurse -File -Filter $Filter -Exclude $excludedExtensions -ErrorAction SilentlyContinue |
                Select-String $Text -ErrorAction SilentlyContinue | ForEach-Object {
                    $contentMatchesFound = $true
                    Write-Host "Match in $($_.Path):$($_.LineNumber) - $($_.Line.Trim())" -ForegroundColor $fcolor
                }
            if (-not $contentMatchesFound) {
                Write-Host "No content matches found." -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Error "An error occurred during search: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function Find-Text

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
# The actual int vs % changes depending on the specific display's resolution
# '0' is the recommended scale for a given display and then it goes up in 25% increments
# If less than the recommended scale is needed, it gets weird. 4294967295 is -25% (if supported by the display)
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

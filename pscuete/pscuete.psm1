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
            Invoke-Expression "python ./speedtest-cli.py --single --simple"
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
$excludedExtensions = @('*.exe', '*.dll', '*.bin', '*.obj', '*.pdb',
            '*.zip', '*.rar', '*.7z', '*.tar', '*.gz',
            '*.png', '*.jpg', '*.jpeg', '*.gif', '*.bmp', '*.ico', '*.tiff', '*.webp',
            '*.mp3', '*.mp4', '*.wav', '*.avi', '*.mov', '*.mkv', '*.flac',
            '*.pdf', '*.doc', '*.docx', '*.xls', '*.xlsx', '*.ppt', '*.pptx',
            '*.iso', '*.img', '*.msi', '*.lib', '*.a', '*.so', '*.dylib',
            '*.pyc', '*.class', '*.cache')

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

# Displays environment variables and optionally highlights matches
function Show-Env
{
    Param(
        [string]$Highlight
    )
    if ($Highlight) {
        $envList = Get-ChildItem Env: | Where-Object { $_.Name -like "*$Highlight*" -or $_.Value -like "*$Highlight*" } | ForEach-Object {
            [PSCustomObject]@{
                Name  = "`e[33m$($_.Name)`e[0m"
                Value = "`e[33m$($_.Value)`e[0m"
            }
        }
        $envList | Format-Table -AutoSize
    } else {
        Get-ChildItem Env: | Select-Object Name, Value | Format-Table -AutoSize
    }
}
Export-ModuleMember -Function Show-Env

function Invoke-Dev {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateSet('build','run')]
        [string]$Command,
        [switch]$BackendOnly,
        [switch]$FrontendOnly,
        [switch]$Docker
    )

    $Root = (Get-Location).Path

    # helpers
    function _step($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
    function _ok($m)   { Write-Host "    $m"   -ForegroundColor Green }
    function _warn($m) { Write-Host "    $m"   -ForegroundColor Yellow }
    function _err($m)  { Write-Host "    ERROR: $m" -ForegroundColor Red }

    # detection
    $hasPackageJson   = Test-Path "$Root\package.json"
    $hasRequirements  = Test-Path "$Root\requirements.txt"
    $hasPyProject     = Test-Path "$Root\pyproject.toml"
    $hasSetupPy       = Test-Path "$Root\setup.py"
    $hasDockerCompose = @(Get-ChildItem "$Root\docker-compose*" -ErrorAction SilentlyContinue).Count -gt 0
    $hasDockerfile    = Test-Path "$Root\Dockerfile"

    $isPython    = $hasRequirements -or $hasPyProject -or $hasSetupPy
    $isNode      = $hasPackageJson
    $isFullStack = $isPython -and $isNode

    # node package manager
    function _pm {
        if (Test-Path "$Root\yarn.lock")      { return 'yarn' }
        if (Test-Path "$Root\pnpm-lock.yaml") { return 'pnpm' }
        return 'npm'
    }

    # python run info: returns @{ exe; runArgs; port; type } or $null
    function _pythonInfo {
        $venv = "$Root\venv"
        $py   = if (Test-Path "$venv\Scripts\python.exe") { "$venv\Scripts\python.exe" } else { 'python' }
        $req  = if ($hasRequirements) { Get-Content "$Root\requirements.txt" -Raw } else { '' }

        if ($req -match 'uvicorn') {
            $candidates = @(
                @{ file = 'src\main.py'; mod = 'src.main:app' },
                @{ file = 'main.py';     mod = 'main:app'     },
                @{ file = 'app\main.py'; mod = 'app.main:app' },
                @{ file = 'app.py';      mod = 'app:app'      }
            )
            foreach ($c in $candidates) {
                if (Test-Path "$Root\$($c.file)") {
                    return @{ exe = $py; runArgs = "-u -m uvicorn $($c.mod) --reload --port 5000"; port = 5000; type = 'uvicorn' }
                }
            }
        }
        if ($req -match 'streamlit') {
            foreach ($f in @('app.py', 'ui\app.py', 'streamlit_app.py')) {
                if (Test-Path "$Root\$f") {
                    return @{ exe = $py; runArgs = "-m streamlit run $f"; port = 8501; type = 'streamlit' }
                }
            }
        }
        foreach ($f in @('main.py', 'app.py', 'run.py', 'server.py')) {
            if (Test-Path "$Root\$f") {
                return @{ exe = $py; runArgs = "-u $f"; port = $null; type = 'script' }
            }
        }
        return $null
    }

    # node run info: returns @{ pm; script; port }
    function _nodeInfo {
        $pm      = _pm
        $pkgJson = Get-Content "$Root\package.json" -Raw | ConvertFrom-Json
        $scripts = $pkgJson.scripts
        $scr     = if ($scripts.dev)        { 'dev'   } `
                   elseif ($scripts.start)  { 'start' } `
                   else                     { $null   }
        return @{ pm = $pm; script = $scr; port = 3000 }
    }

    # BUILD helpers
    function _buildPython {
        _step 'Python: virtual environment'
        $venv = "$Root\venv"
        if (-not (Test-Path $venv)) { python -m venv $venv; _ok 'venv created' } else { _ok 'venv exists' }
        if (Test-Path "$venv\Scripts\Activate.ps1") { & "$venv\Scripts\Activate.ps1"; _ok 'venv activated' }
        $pyExe = if (Test-Path "$venv\Scripts\python.exe") { "$venv\Scripts\python.exe" } else { 'python' }
        _step 'Python: installing dependencies'
        if ($hasRequirements) { & $pyExe -m pip install -r "$Root\requirements.txt" --quiet; _ok 'requirements.txt installed' }
        if ($hasPyProject)    { & $pyExe -m pip install -e . --quiet;                        _ok 'pyproject.toml installed'   }
        _step 'Python: checking .env'
        if (-not (Test-Path "$Root\.env")) {
            if (Test-Path "$Root\.env.example") { Copy-Item "$Root\.env.example" "$Root\.env"; _warn '.env created from .env.example — update secrets' }
            else { _warn 'no .env.example found; create .env manually if needed' }
        } else { _ok '.env exists' }
    }

    function _buildNode {
        $pm = _pm
        _step "Node ($pm): installing dependencies"
        Push-Location $Root
        try {
            & $pm install; _ok 'dependencies installed'
            $pkgJson = Get-Content "$Root\package.json" -Raw | ConvertFrom-Json
            if ($pkgJson.scripts.build) { _step "Node ($pm): building"; & $pm run build; _ok 'build complete' }
        } finally { Pop-Location }
    }

    # RUN helpers — spawn a new pwsh window with color-coded log output.
    # `$_ is escaped so it evaluates in the child process, not at here-string expansion time.
    function _runPython {
        $info = _pythonInfo
        if (-not $info) { _err "Could not detect Python entry point in $Root"; return }
        $exe   = $info.exe
        $rargs = $info.runArgs
        $label = $info.type
        $port  = if ($info.port) { $info.port } else { '?' }
        $venvActivate = "$Root\venv\Scripts\Activate.ps1"
        $script = @"
Write-Host 'Python ($label) -> http://localhost:$port' -ForegroundColor Gray
Write-Host 'Press Ctrl+C to stop.`n'
Set-Location '$Root'
if (Test-Path '$venvActivate') { & '$venvActivate' }
& '$exe' $rargs 2>&1 | ForEach-Object {
    if (`$_ -match 'ERROR|error:|Exception')                             { Write-Host `$_ -ForegroundColor Red }
    elseif (`$_ -match 'WARNING|warn:')                                  { Write-Host `$_ -ForegroundColor DarkYellow }
    elseif (`$_ -match '"/app|/assets/|\.js|\.css|\.html|\.ico|\.map')  { Write-Host `$_ -ForegroundColor Yellow }
    else                                                                  { Write-Host `$_ -ForegroundColor Gray }
}
"@
        _ok "Launching Python ($label) in new window -> http://localhost:$port"
        Start-Process pwsh -ArgumentList '-NoProfile', '-NoExit', '-Command', $script
    }

    function _runNode {
        $info   = _nodeInfo
        $pm     = $info.pm
        $scr    = $info.script
        $port   = $info.port
        $runCmd = if ($scr) { "$pm run $scr" } else { "$pm start" }
        $script = @"
Write-Host 'Node ($pm) -> http://localhost:$port' -ForegroundColor Gray
Write-Host 'Press Ctrl+C to stop.`n'
Set-Location '$Root'
& $runCmd 2>&1 | ForEach-Object {
    if (`$_ -match 'ERROR|error:|Exception')                             { Write-Host `$_ -ForegroundColor Red }
    elseif (`$_ -match 'WARNING|warn:')                                  { Write-Host `$_ -ForegroundColor DarkYellow }
    elseif (`$_ -match '"/app|/assets/|\.js|\.css|\.html|\.ico|\.map')  { Write-Host `$_ -ForegroundColor Yellow }
    else                                                                  { Write-Host `$_ -ForegroundColor Gray }
}
"@
        _ok "Launching Node ($pm) in new window -> http://localhost:$port"
        Start-Process pwsh -ArgumentList '-NoProfile', '-NoExit', '-Command', $script
        Start-Sleep -Seconds 3
        Start-Process "http://localhost:$port"
    }

    function _buildDocker {
        if ($hasDockerCompose) {
            _step 'Docker Compose: building'
            $composeFile = Get-ChildItem "$Root\docker-compose*" -ErrorAction SilentlyContinue | Select-Object -First 1
            docker compose -f $composeFile.Name build
            _ok 'docker compose build complete'
        } elseif ($hasDockerfile) {
            $imageName = (Split-Path $Root -Leaf).ToLower()
            _step "Docker: building image '$imageName'"
            docker build -t $imageName .
            _ok 'docker build complete'
        } else {
            _err 'No Dockerfile or docker-compose.yml found'
        }
    }

    function _runDocker {
        if ($hasDockerCompose) {
            _step 'Docker Compose: up'
            $composeFile = Get-ChildItem "$Root\docker-compose*" -ErrorAction SilentlyContinue | Select-Object -First 1
            docker compose -f $composeFile.Name up -d
        }
        elseif ($hasDockerfile) {
            $imageName = (Split-Path $Root -Leaf).ToLower()
            _step "Docker: running container '$imageName'"
            docker run --rm -it $imageName
        }
        else {
            _err 'No Dockerfile or docker-compose.yml found'
        }
    }

    # DISPATCH
    if ($Command -eq 'build') {
        if ($Docker) { _buildDocker }
        elseif ($isFullStack) {
            if     ($FrontendOnly) { _buildNode }
            elseif ($BackendOnly)  { _buildPython }
            else                   { _buildPython; _buildNode }
        }
        elseif ($isPython) { _buildPython }
        elseif  ($isNode)    { _buildNode }
        else { _err "No recognizable project found in $Root" }
        Write-Host "`nBuild complete." -ForegroundColor Green
    }
    elseif ($Command -eq 'run') {
        if ($Docker) { _runDocker }
        elseif ($isFullStack) {
            if     ($FrontendOnly) { _runNode }
            elseif ($BackendOnly)  { _runPython }
            else                   { _runPython; _runNode }
        }
        elseif ($isPython) { _runPython }
        elseif  ($isNode)    { _runNode }
        else { _err "No recognizable project found in $Root" }
    }
    else {
        Write-Host 'Usage: dev build|run [-BackendOnly] [-FrontendOnly] [-Docker]' -ForegroundColor Yellow
        Write-Host '  build          Build (auto-detects: Python/Node)'             -ForegroundColor DarkGray
        Write-Host '  run            Run in a new window (auto-detects type)'       -ForegroundColor DarkGray
        Write-Host '  -BackendOnly   Target Python/backend only (full-stack)'       -ForegroundColor DarkGray
        Write-Host '  -FrontendOnly  Target Node/frontend only (full-stack)'        -ForegroundColor DarkGray
        Write-Host '  -Docker        Build/run via Docker (compose or Dockerfile)'  -ForegroundColor DarkGray
        Write-Host "`nDetects: Python (FastAPI/uvicorn, Streamlit, plain), Node (npm/yarn/pnpm)" -ForegroundColor DarkGray
        Write-Host "Docker:  use -Docker flag to target Dockerfile or docker-compose*.yml"        -ForegroundColor DarkGray
    }
}
Export-ModuleMember -Function Invoke-Dev

# Loads the remote git URL of the current repository in the default browser
function Start-GitRepo
{
    try {
        $remoteUrl = git remote get-url origin 2>$null
        if ([string]::IsNullOrWhiteSpace($remoteUrl)) {
            Write-Error "No remote URL found for this repository."
            return
        }
        Start-Process $remoteUrl
    }
    catch {
        Write-Error "Failed to open repository: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function Start-GitRepo

function Open-PSCuete
{
    try {
        code $profile "$ENV:OneDrive\Documents\PowerShell\Modules\pscuete\pscuete.psm1"
    }
    catch {
        Write-Error "Failed to open PSCuete module: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function Open-PSCuete
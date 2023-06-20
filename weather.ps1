$locations = "seattle+wa,london"
$weatherInfo = curl -s "wttr.in/{$locations}?format=%l:+%c+%t+%p+%w\n"
$weatherResults = @()

foreach($w in $weatherInfo)
{
    $segments = $w -split "\s+"
    $city = $segments[0]
    $weather = $segments[1]
    $temperatureF = $segments[2]
    $precipitation = $segments[3]
    $wind = $segments[4]

    $temperatureF = $temperatureF -replace "\D", ""
    $temperatureC = [int][math]::Round(($temperatureF - 32) * 5 / 9, 0)

    $weatherObject = [PSCustomObject]@{
        City = $city
        Weather = $weather
        TempF = $temperatureF
        TempC = $temperatureC
        Precip = $precipitation
        Wind = $wind
    }
    $weatherResults += $weatherObject
}

$weatherResults | Format-Table -AutoSize
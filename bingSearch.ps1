Param (
    [Parameter(Mandatory=$true)]
    [Alias('q')]
    [string]$query,
    [Parameter(Mandatory=$false)]
    [switch]$news=$false,
    [Parameter(Mandatory=$false)]
    [int]$answercount = 3
)

$bingEndpoint = "" #Insert Bing Endpoint here
$apiKey = "" #Insert API Key here
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
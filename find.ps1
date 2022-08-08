Param (
    [string]$path,
    [string]$filter,
    [string]$text,
    [switch]$q = $true, #quick - folder and file names only
    [switch]$e = $false #extended - within file text
    )
Write-Host "Usage: find -text {text} -path {path} -filter {filter}" -ForegroundColor $fcolor
if($path -eq $null -or $path -eq "")
{
    $path = Get-Location | Select-Object -ExpandProperty Path
}

if ($q)
{
    #Directory names first
    Write-Host "Searching directory names..." -ForegroundColor $fcolor
    Get-ChildItem $path -Recurse -Directory -Filter "*$($text)*" | Select-Object Name | Format-Table $_.Value
    #| Where-Object {$_.Name -like "*$($text)*"} 
    
    #File names second
    Write-Host "Searching file names..." -ForegroundColor $fcolor
    Get-ChildItem $path -Recurse -File -Filter "*$($text)*"  -Exclude *.exe,*.dll | Select-Object Name | Format-Table $_.Value
}

if ($e)
{
    #File text third
    Write-Host "Searching file contents..." -ForegroundColor $fcolor
    Get-ChildItem $path -Recurse -Filter $filter -Exclude *.exe,*.dll | Select-String $text | Select-Object Path,Linenumber,Line | Format-Table $_.Value
}
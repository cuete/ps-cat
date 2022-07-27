# This script creates as a virtual clipboard for files
#   PS> copi file.ext
# copies the file path to a global variable (string list) 
# acting as a stack
# Use peis.ps1 to paste the file in a new path

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
Write-Host "Added to clipboard, stack is: "
foreach ($file in $global:fileList)
{
    Write-Host "`t$($file)"
}
$global:fileList += $sourcePath + '\' + $filename

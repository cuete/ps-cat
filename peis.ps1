# This script acts as a virtual clipboard for files in conjunction with copi.ps1
#   PS> peis
# pastes the file at the top of the stack of the global variable (string list) 
# in the current directory
# Use copi.ps1 to copy the source file path

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

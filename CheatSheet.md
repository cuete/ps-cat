# Variables
    $array = @("value","value", 1)

    $array = @(
        "value"
        "value"
        1)

    $arraylist = New-Object System.Collections.ArrayList
    $arraylist.Add($item)

    $global:variable = $value
    Clear-Variable -Scope Global -Name variable

# Objects
    $object = [PSCustomObject]@{
        Property1 = $value
        Property2 = 'Value'
        Property3 = 1
    }
    $object | Add-Member -Name Property1 -Value $value

# Parameters
    Param (
        [Parameter(Position=0)(Mandatory=$true)]
        [string]$operation,
        [Parameter()]
        [Alias('n')]
        [string]$name,
        [switch]$flag = $false,
        [int]$count = 1)

    Param($s=0)

# Pipe cmdlets
    | Select-Object -ExpandProperty PropertyName

    | Where-Object { $_.Property -match $filter }

    | Format-Table -Wrap -AutoSize

    | Format-List

    | Sort-Object Property

    | Select-Object Property -last 1

    | Out-File -FilePath $filepath
    $text = Get-Content $filepath | Out-String | ConvertFrom-Json

    | Foreach-Object { <command> }

# Misc cmdlets
    $path = Get-Location | Select-Object -ExpandProperty Path
    $fullpath = Join-Path $path $filename

    $files = Get-ChildItem -Path $path -Filter $prefix* | Where-Object { $_.LastWriteTime -gt (Get-Date 2019-04-21) } | Sort-Object LastWriteTime 

    Invoke-Sqlcmd -InputFile $file -ConnectionString $connectionString
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $query -As DataRows | Format-Table

    (Get-Date).AddDays(1)
    Get-Date -Format "yyyyMMddHHmm"

    -ErrorAction SilentlyContinue

# Snippets
    foreach ($item in $array)
    {
    }

    if(!$variable)
    {
        return $variable
    }
    else
    {
    }

    try
    {
    }
    catch
    {
        $_.Exception.Message
    }

    switch ($operation)
    {
        "operation1" { <commands> }
        "operation2" { <commands> }
        default { "Invalid operation - " + $operation }
    }

    Function($variable)
    function Function($variable)
    {
        Param()
    }

# Script
    $script = {python .\script.py}
    Invoke-Command -ScriptBlock $script

    $script | Invoke-Expression

# APIs
    $headers = @{
        "Accept" = "application/json"
        "User-Agent" = "(parameter, value)"
        }
    Invoke-RestMethod -Uri $url -Method Get -Headers $headers

    $restparameters = @{
        Headers = @{'Content-Type'='application/json'}
        Body = $message | ConvertTo-Json
        Method = 'Post'
        URI = $uri
        }
    Invoke-RestMethod @restparameters

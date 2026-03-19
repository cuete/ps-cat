# search for a file name recursively
# wildcards * are allowed

param ([Parameter(Mandatory=$true)][string]$query,[Parameter(Mandatory=$true)][string]$rootDir)

Get-ChildItem $rootDir -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.name -like $query }

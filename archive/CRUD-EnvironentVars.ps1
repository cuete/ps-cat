# CRUD operations with a single registry variable on Windows

param ([Parameter(Mandatory=$true)][string]$keyname,[Parameter(Mandatory=$true)][string]$value)

Write-Host "Setting environment variables {0} to {1}..." -f $keyname, $value

#set one environment variable
[Environment]::SetEnvironmentVariable($keyname, $value, "User") #[User|Machine]

#show environment variable
Get-ChildItem Env:$keyname | Format-List

#delete environment variable
[Environment]::SetEnvironmentVariable($keyname,$null,"User")

#list environment variable
[Environment]::GetEnvironmentVariable($keyname,"User") #[User|Machine]

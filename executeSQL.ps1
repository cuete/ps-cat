#Executes a sql script on a given connection string
#Required: Install-Module -Name SqlServer

param ([string]$file,[string]$server,[string]$database,[string]$user,[string]$password)

$cstr = "Data Source=$server;Initial Catalog=$database;User Id=$username;password=$password"
Invoke-Sqlcmd -InputFile $file -ConnectionString $cstr 

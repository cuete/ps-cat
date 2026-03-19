# CRUD operations with multiple registry variable on Windows stored on an xml file
# handles different cases for different hosts
# variables.congif
# 
# <?xml version="1.0" encoding="UTF-8"?>
# <Environments>
#     <Environment name="hostname1">
#         <keyname1>value1</keyname1>
#         <keyname2>value2</keyname2>
#         <keyname3>value3</keyname3>
#     </Environment>
#     <Environment name="hostname2">
#         ...
#     </Environment>    
# </Environments>

param ([Parameter(Mandatory=$true)][string]$hostname)

Write-Host "Setting environment variables(s) for $hostname..."

#set a batch of environment variables from xml file source
[xml]$EnvironmentConfigXML = Get-Content .\variables.config
$variables = $EnvironmentConfigXML.SelectSingleNode("//Environments/Environment[@name='$hostname']") #xpath
$variables.ChildNodes | % { 
    "{0} -> {1}" -f $_.name, $_.InnerText 
    [Environment]::SetEnvironmentVariable($_.name, $_.InnerText, "User") #[User|Machine]
}

$variables.ChildNodes | % { 
	[Environment]::GetEnvironmentVariable($_.name,"User") #[User|Machine]	
}


#displays the content of a file
#waits for new content to be written to the file
#filters lines by content

# $server = string, server id
# $e = flag, filter error/warning/info/debug lines only?
# $w = flag, wait for new lines?
# $filter = string, filter criteria for log file names
param ([Parameter(Mandatory=$true)][string]$server,[switch]$e=$false,[switch]$w=$false,[string]$level="ERROR",[string]$filter="default*")

switch ($server) {
    s1 { $path = "//server1" }
    s2 { $path = "//server2" }
}
$path = $path + "/path/logs/"

#get the latest log file that matches the criteria
$file = Get-ChildItem -Path $path -Filter $filter | Sort-Object LastWriteTime | Select-Object Name -last 1

$exp = 'Get-Content ' + $path + $file.Name
if ($w){
    $exp = $exp + ' -wait'
}
if ($e){
    $exp = $exp + ' | where { $_ -match $level }'
}
Invoke-Expression $exp

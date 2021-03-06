param ([Parameter(Mandatory=$true)][string]$file)

Get-Content $file -First 2

#The header pattern matches a Fiddler Web Debugger capture
#1	200	HTTP	www.w3.org	/path/page.html	249	public, must-revalidate; Expires: Fri, 01 Jan 2018 00:00:00 GMT	text/css	chrome:666
		
Import-Csv $file -Header "#","Reuslt","Protocol","Host","URL","Body","Caching","Content-Type","Process","Comments","Custom" -Delimiter "`t" | Select-Object Host | Where-Object { $_.Host -notlike "Tunnel*" } | Sort-Object -Property Host | Get-Unique -AsString | Measure-Object | Select-Object Count

Import-Csv $file -Header "#","Reuslt","Protocol","Host","URL","Body","Caching","Content-Type","Process","Comments","Custom" -Delimiter "`t" | Select-Object Host | Where-Object { $_.Host -notlike "Tunnel*" } | Sort-Object -Property Host | Get-Unique -AsString > output.txt

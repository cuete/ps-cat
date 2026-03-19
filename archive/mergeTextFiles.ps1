#Merge multiple text files in a directory into one large file

#Filter directory contents by extension
$directory = "C:\path\to\dir\*.csv"
$outFile = "C:\path\to\outfile.csv"

Get-ChildItem $directory | foreach {[System.IO.File]::AppendAllText($outFile, [System.IO.File]::ReadAllText($_.FullName))}

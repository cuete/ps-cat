# upload a file to an ftp server

$server = "ftp://server/"
$filepath = "files/myfile.txt"
$sourceFile = "F:\files\myfile.txt"
$user = ""
$password = ""

$ftp = [System.Net.FtpWebRequest]::Create("$server$filepath")
$ftp = [System.Net.FtpWebRequest]$ftp
$ftp.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
$ftp.Credentials = new-object System.Net.NetworkCredential($user,$password)
$ftp.UseBinary = $true
$ftp.UsePassive = $true

$content = [System.IO.File]::ReadAllBytes($sourceFile)
$ftp.ContentLength = $content.Length

$rs = $ftp.GetRequestStream()
$rs.Write($content, 0, $content.Length)

$rs.Close()
$rs.Dispose()

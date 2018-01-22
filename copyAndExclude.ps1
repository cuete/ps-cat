$source = "F:\sourceDir\"
$destination = "F:\destinationDir\"
$exclude = @("F:\sourceDir\excldeThisDirectory", "*thisOneToo*","[b|B]in")

Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination {Join-Path $destination $_.FullName.Substring($source.length)}

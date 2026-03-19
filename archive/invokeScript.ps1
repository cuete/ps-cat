#run an external scipt

$script = {python .\script.py}
Invoke-Command -ScriptBlock $script

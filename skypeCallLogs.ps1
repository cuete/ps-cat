# Takes a Skype call log file (csv) and calculates the total minutes talked. 

$file = "" #your file

Import-Csv $file -Header "Date","Date1","Item","Destination","Type","Rate","Duration","Amount","Currency" -Delimiter ";" | Select-Object Duration > tmp.csv

(Import-Csv ./tmp.csv -Header "H","M","S" -Delimiter ":" | Measure-Object M -Sum).Sum + (Import-Csv ./callsDurations.csv -Header "H","M","S" -Delimiter ":" | Measure-Object S -Sum).Sum/60

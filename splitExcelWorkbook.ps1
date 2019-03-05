#Split each sheet in an MS Excel workbook into multiple files of a given output format  

$Excel = New-Object -ComObject "Excel.Application" 
$Excel.Visible = $false #Runs Excel in the background. 
$Excel.DisplayAlerts = $false #Supress alert messages. 

$filepath ="C:\path\to\file.xlsx"
$Workbook = $Excel.Workbooks.open($filepath)
$WorkbookName = "file.xlsx"
$output_type = "csv"

if ($Workbook.Worksheets.Count -gt 0) { 
    write-Output "Now processing: $WorkbookName" 
    #See list of output formats at https://docs.microsoft.com/en-us/dotnet/api/microsoft.office.interop.excel.xlfileformat
    $FileFormat = [Microsoft.Office.Interop.Excel.XlFileFormat]::xlCSV 

    $WorkbookName = $filepath -replace ".xlsx", "" 

    foreach($Worksheet in $Workbook.Worksheets) {
        $Worksheet.Copy()
        $ExtractedFileName = $WorkbookName + "-" + $Worksheet.Name + "." + $output_type 
        $Excel.ActiveWorkbook.SaveAs($ExtractedFileName, $FileFormat) 
        $Excel.ActiveWorkbook.Close

        Write-Output "Created file: $ExtractedFileName"
    }
} 

$Workbook.Close() 
$Excel.Quit() 
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)
Stop-Process -Name EXCEL
Remove-Variable Excel
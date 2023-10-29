$PrinterName = "NamePrintTest-PRT1"

Try {
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($PrinterExist)
    {
        Write-Host ("Print Installed '{0}'" -f $PrinterName)
        Exit 1
    }
}
Catch
{
    Write-Host ("Error Remove Print ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message) -ForegroundColor Red
}

Exit 0
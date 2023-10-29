$PrinterName    = "NamePrintTest-PRT1"

$regPathPrint = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\{0}" -f $PrinterName
$regVal       = Get-ItemProperty -Path $regPathPrint -ErrorAction SilentlyContinue

if ($regVal -and $regVal.name -eq $PrinterName)
{
    Write-Host ("Print Installed '{0}'" -f $PrinterName)
    Exit 1
}
else
{
    Exit 0
}
$printName    = "NamePrintTest-PRT1"
$regPathPrint = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Print\Printers\{0}" -f $printName

$regVal = Get-ItemProperty -Path $regPathPrint -ErrorAction SilentlyContinue
if ($regVal -and $regVal.name -eq $printName)
{
    Write-Host "Print Installed"
    Exit 1
}
else
{
    Exit 0
}
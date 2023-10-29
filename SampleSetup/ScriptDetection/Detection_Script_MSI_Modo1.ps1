
$AppIDMsi = "{ID_de_Tu_Aplicacion_MSI}"

$installedApps = Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq $AppIDMsi}
if ($null -ne $installedApps)
{
    Write-Host ("Installed '{0}'" -f $AppIDMsi)
    Exit 0
}
else
{
    Exit 1
}
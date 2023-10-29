$AppName   = "Microsoft.WindowsStore"

$CountApps = (Get-AppxPackage -AllUsers | Where-Object { $_.Name -eq $AppName }).Count
if ($CountApps -eq '0')
{
    Write-Host ("Software ({0}) not Installed" -f $AppName)
    Exit 1
}
else
{
    Write-Host  ("Software ({0}) Installed" -f $AppName)
    Exit 0
}
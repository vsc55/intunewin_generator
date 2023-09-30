
$AppName   = "*HP Wolf*"
$CountApps = (Get-Package | Where-Object { $_.Name -like $AppName }).Count

if ($CountApps -eq '0')
{
    Write-Host "Software not Installed"
    Exit 0
}
else
{
    Write-Host "Software Installed"
    Exit 1
}
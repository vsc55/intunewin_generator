$netFx35 = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'NetFx3*'}

if ($null -ne $netFx35 -and $netFx35.State -eq 'Installed')
{
    Write-Host "Installed"
    Exit 0
}
else
{
    Write-Host "No Installed"
    Exit 1
}
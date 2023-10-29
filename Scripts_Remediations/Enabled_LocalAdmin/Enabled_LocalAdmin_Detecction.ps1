$adminName    = (Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.SID -like 'S-1-5-21-*-500' }).Name
$adminAccount = Get-LocalUser -Name $adminName
if ($adminAccount.Enabled -eq $false)
{
    Write-Host "Local Admin is Disabled"
    Exit 1
}
else
{
    Exit 0
}
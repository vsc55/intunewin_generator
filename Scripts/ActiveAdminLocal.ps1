$adminName = (Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.SID -like 'S-1-5-21-*-500' }).Name
Write-Host ("UserName Local Admin: {0}" -f $adminName)

$adminAccount = Get-LocalUser -Name $adminName
if ($adminAccount.Enabled -eq $false)
{
    Enable-LocalUser -Name $adminName
    Write-Host "The local administrator has been enabled."
}
else {
    Write-Host "The local administrator is already enabled."
}
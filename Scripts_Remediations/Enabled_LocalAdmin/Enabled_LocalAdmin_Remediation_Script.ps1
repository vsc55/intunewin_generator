# No compatible con PW 7
# Valido para el PW que trae el sistema version 5.

$errCode   = 0
$adminName = ""
Try {
    $adminName = (Get-WmiObject -Class Win32_UserAccount | Where-Object { $_.SID -like 'S-1-5-21-*-500' }).Name
    Write-Host ("UserName Local Admin: {0}" -f $adminName) -ForegroundColor Green
}
Catch
{
    $errCode = $_.Exception.HResult
    $errMsg  = $_.Exception.Message
    Write-Warning -Message ("Failed to enabled user '{0}'. Error ({1}): {2}" -f $adminName, $errCode, $errMsg)
}

if ($errCode -eq "0")
{
    $adminAccount = Get-LocalUser -Name $adminName
    if ($adminAccount.Enabled -eq $false)
    {
        Try {
            Enable-LocalUser -Name $adminName
            Write-Host "The local administrator has been enabled."
        }
        Catch {
            $errCode = $_.Exception.HResult
            $errMsg  = $_.Exception.Message
            Write-Warning -Message ("Failed to enabled user '{0}'. Error ({1}): {2}" -f $adminName, $errCode, $errMsg)
        }
    }
    else
    {
        Write-Host "The local administrator is already enabled."
    }
}

Exit $errCode
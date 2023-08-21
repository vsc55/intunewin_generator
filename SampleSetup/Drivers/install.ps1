# Changelog:
# ----------
#   04/08/2023 - Creacion Script. (Javier Pastor)

# Intune Cmd:
# Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\install.ps1
#
# Ejemplo pnputil.exe:
# "C:\Windows\System32\pnputil.exe" /add-driver "C3422WE.inf" /install >> "C:\Windows\Temp\DELL_C3422WE_log.txt"
#

$InfFile     = "C3422WE.inf"
$LogFilePath = "C:\Windows\Temp\log_DELL_C3422WE_log.txt"
Start-Transcript -Path $LogFilePath -Append

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch
    {
        $msgErr = "Failed to start $PSCOMMANDPATH"
        $msgErr | Out-File -FilePath $logFilePath -Append
        Throw $msgErr
    }
    Exit
}

$pnputilPath     = "C:\Windows\system32\pnputil.exe"
$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$InfFilePath     = Join-Path -Path $ScriptDirectory -ChildPath $InfFile

$errCode = 0
$errMsg  = ""

try
{
    $ProcessInfo = Start-Process -FilePath $pnputilPath -ArgumentList "/add-driver `"$InfFilePath`" /install" -WindowStyle Hidden -RedirectStandardOutput $LogFilePath -Wait -PassThru
    $errCode = $ProcessInfo.ExitCode
    $errMsg  = $ProcessInfo.StandardError
}
catch
{  
    $errCode = $_.Exception.HResult
    $errMsg = $_.Exception.Message
}

if ($errCode -eq 0 -or $errCode -eq 259 -or $errCode -eq 3010)
{
    $msg = "Install OK"
    Write-Host $msg
    $msg | Out-File -FilePath $logFilePath -Append
    Stop-Transcript
    Exit 0
}
else
{
    $msg =  "Error ($errCode): $errMsg"
    Write-Host $msg
    $msg | Out-File -FilePath $logFilePath -Append
    Stop-Transcript
    Exit 1
}
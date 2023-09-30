# Name of the app to uninstall
$script_name ="Remove_HPDocumentation"

# Name of the app to uninstall
$CmdUnintall = "C:\Program Files\HP\Documentation\Doc_Uninstall.cmd"


$errCode     = 0
$errMsg      = ""
$file_log    = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

if (Test-Path -Path $CmdUnintall -PathType Leaf)
{
    Write-Host -Object "Attempting to uninstall..."
    Try 
    {
        Invoke-Expression -Command ('cmd.exe /C "{0}"' -f $CmdUnintall)
        Write-Host -Object "Successfully uninstalled."
    }
    Catch
    {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Warning -Message ("Failed to uninstall - ({1}): {2}" -f $errCode, $errMsg )
    }
}
else
{
    Write-Host "Skip, Software not detected!"
}

Stop-Transcript
Exit $errCode
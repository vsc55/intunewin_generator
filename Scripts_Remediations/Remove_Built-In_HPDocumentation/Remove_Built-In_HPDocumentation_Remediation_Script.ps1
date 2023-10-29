$script_name   = "Remove_HPDocumentation"
$path_unintall = "C:\Program Files\HP\Documentation\Doc_Uninstall.cmd"


$file_log    = "log_remediation_{0}.log" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

$errCode = 0
if (Test-Path -Path $path_unintall -PathType Leaf)
{
    # CMD /C $path_unintall

    Write-Host -Object "Attempting to uninstall..."
    Try
    {
        Invoke-Expression -Command ('cmd.exe /C "{0}"' -f $path_unintall)
        Write-Host -Object "Successfully uninstalled."
    }
    Catch {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Warning -Message ("Failed to uninstall ({0}): {1}" -f $errCode, $errMsg)
    }
}
else
{
    Write-Host "Skip, Software not detected!"
}

Stop-Transcript
Exit $errCode
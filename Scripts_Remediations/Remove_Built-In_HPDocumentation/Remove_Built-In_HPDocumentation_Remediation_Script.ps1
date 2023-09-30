$script_name ="Remove_HPDocumentation"

$file_log  = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

$path_unintall = "C:\Program Files\HP\Documentation\Doc_Uninstall.cmd"

if (Test-Path -Path $path_unintall -PathType Leaf) {
    # CMD /C $path_unintall

    Write-Host -Object "Attempting to uninstall..."
    Try 
    {
        Invoke-Expression -Command ('cmd.exe /C "{0}"' -f $path_unintall)
        Write-Host -Object "Successfully uninstalled."
    }
    Catch {
        $errCode = $_.Exception.HResult
        Write-Warning -Message "Failed to uninstall ($errCode)"
    }
}
else
{
    Write-Host "Skip, Software not detected!"
}

Stop-Transcript
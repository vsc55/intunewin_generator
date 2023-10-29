$script_name = "Remove_HPWolf"
$AppName     = "*HP Wolf*"


$errCode     = 0
$file_log    = "log_remediation_{0}.log" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append


# Debug
Write-Host ""
Get-Package | Where-Object  { $_.Name -like $AppName }
Write-Host ""


$InstalledPrograms = Get-Package | Where-Object  { $_.Name -like $AppName }
$InstalledPrograms | ForEach-Object {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Warning -Message ("Failed to uninstall ({0}) [{1}]: {2}" -f $errCode, $($_.Name) , $errMsg)
    }
}

Stop-Transcript
Exit $errCode
$script_name ="Remove_HPWolf"

$file_log  = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

$AppName           = "*HP Wolf*"
$InstalledPrograms = Get-Package | Where-Object  { $_.Name -like $AppName }

Write-Host ""
Get-Package | Where-Object  { $_.Name -like $AppName }
Write-Host ""

$InstalledPrograms | ForEach-Object {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {
        $errCode = $_.Exception.HResult
        Write-Warning -Message "Failed to uninstall ($errCode): [$($_.Name)]"
    }
}

Stop-Transcript
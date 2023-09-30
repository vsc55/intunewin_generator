# Name LogFile
$script_name ="Remove_HPWolf"

# Name of the app to uninstall
$AppName = "*HP Wolf*"


$errCode     = 0
$errMsg      = ""
$file_log    = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append


$InstalledPrograms = Get-Package | Where-Object  { $_.Name -like $AppName }

# Debug: List of packages detected
Write-Host ""
Get-Package | Where-Object  { $_.Name -like $AppName } | Format-Table -Property Name, Version, ProviderName
Write-Host ""

$InstalledPrograms | ForEach-Object {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Warning -Message ("Failed to uninstall [{0}] - ({1}): {2}" -f $_.Name, $errCode, $errMsg )
    }
}

Stop-Transcript
Exit $errCode
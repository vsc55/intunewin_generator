$script_name ="Remove_MicrosftTeamsPersoal"

$file_log  = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

$AppName           = "*MicrosoftTeams*"
$InstalledPrograms = Get-AppxPackage -AllUsers | Where-Object  { $_.Name -like $AppName }

Get-AppxPackage -AllUsers | Where-Object  { $_.Name -like $AppName } | Format-Table -Property Name, Version

$InstalledPrograms | ForEach-Object {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers
        Write-Host -Object "Successfully uninstalled: [$($_.PackageFullName)]"
    }
    Catch {
        $errCode = $_.Exception.HResult
        Write-Warning -Message "Failed to uninstall ($errCode): [$($_.Name)]"
    }
}

Stop-Transcript
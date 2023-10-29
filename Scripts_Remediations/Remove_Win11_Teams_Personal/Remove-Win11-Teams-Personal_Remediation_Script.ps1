$script_name ="Remove_MicrosftTeamsPersoal"
$TaskName    = "msteams.exe"
$AppName     = "MicrosoftTeams"


$errCode     = 0
$file_log    = "log_remediation_{0}.log" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append


#Kill Teams Personal EXE if running
TASKKILL /IM $TaskName /f

#Debug App Info
Get-AppxPackage -AllUsers | Where-Object  { $_.Name -like $AppName } | Format-Table -Property Name, Version

#Remove it
$InstalledPrograms = Get-AppxPackage -AllUsers | Where-Object  { $_.Name -like $AppName }
$InstalledPrograms | ForEach-Object {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        Remove-AppxPackage -Package $_.PackageFullName -AllUsers
        Write-Host -Object "Successfully uninstalled: [$($_.PackageFullName)]"
    }
    Catch {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Warning -Message ("Failed to uninstall ({0}) [{1}]: {2}" -f $errCode, $($_.Name), $errMsg)
    }
}

Stop-Transcript
Exit $errCode
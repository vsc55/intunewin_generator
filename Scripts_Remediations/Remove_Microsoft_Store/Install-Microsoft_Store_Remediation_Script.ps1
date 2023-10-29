$script_name = "Install_MicrosftStore"
$AppName     = "Microsoft.WindowsStore*"


$errCode     = 0
$file_log    = "log_remediation_{0}.log" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append


#Debug App Info
Get-AppxPackage -AllUsers | Where-Object  { $_.Name -like $AppName } | Format-Table -Property Name, Version

#Install it
Try {
    Get-AppxPackage -AllUsers $AppName | ForEach-Object {Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml"}
}
Catch {
    $errCode = $_.Exception.HResult
    $errMsg  = $_.Exception.Message
    Write-Warning -Message ("Failed to install ({0}): {2}" -f $errCode, $errMsg)
}

Stop-Transcript
Exit $errCode
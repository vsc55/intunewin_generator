# Name LogFile
$script_name ="Remove_iconsTCO"

# Define paths to remove in array $paths
$paths = @(
    "C:\ProgramData\HP\TCO",
    "C:\Users\Public\Desktop\TCO Certified.lnk",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\TCO Certified.lnk"
)

$errCode     = 0
$errMsg      = ""
$file_log    = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

Foreach ($path in $paths) {
    Try
    {
        if (Test-Path $path -PathType Container)
        {
            Remove-Item -LiteralPath $path -Force -Recurse
        }
        elseif (Test-Path $path -PathType Leaf)
        {
            Remove-Item -Path $path -Force
        }
        else
        {
            Write-Host ("Item [{0}] not found" -f $path)
            continue
        }
        Write-Host ("Item [{0}] removed OK" -f $path)
    }
    catch
    {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Host ("Error to remove [{0}] - Code {1}: {2}" -f $path_remove, $errCode, $errMsg)
    }
}
Stop-Transcript
Exit $errCode
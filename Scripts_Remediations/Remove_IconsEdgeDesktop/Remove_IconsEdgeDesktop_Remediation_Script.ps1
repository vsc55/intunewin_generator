$script_name ="Remove_IconsEdgeDesktop"

$file_log  = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append


# Define paths to remove in array $paths
$paths = @(
    "C:\Users\Public\Desktop\Microsoft Edge.lnk"
)

foreach ($path in $paths) {
    if (Test-Path $path -PathType Container)
    {
        Try {
            Remove-Item -LiteralPath $path -Force -Recurse
            Write-Host ("Shortcut for {0} removed" -f $path)
        } catch {
            Write-Host ("Error deleting {0}: {1}" -f $path, $_.Exception.Message)
        }
    }
    elseif (Test-Path $path -PathType Leaf)
    {
        Try {
            Remove-Item -Path $path -Force
            Write-Host ("Shortcut for {0} removed" -f $path)
        } catch {
            Write-Host ("Error deleting {0}: {1}" -f $path, $_.Exception.Message)
        }
    }
    else
    {
        Write-Host ("Item {0} not found" -f $path)
    }
}

Stop-Transcript
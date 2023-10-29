# Version 1.0
#
# Cahgnelog: Init version.
#

$script_name ="Remove_iconsAdobeOfertas"
$paths       = @(
    "C:\Program Files (x86)\Online Services",
    "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Ofertas Adobe.lnk"
)


$errCode     = 0
$file_log    = "log_remediation_{0}.log" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

foreach ($path in $paths)
{
    if (Test-Path $path -PathType Container)
    {
        Try {
            Remove-Item -LiteralPath $path -Force -Recurse
            Write-Host ("Shortcut for {0} removed" -f $path)
        } catch {
            $errCode = $_.Exception.HResult
            $errMsg  = $_.Exception.Message
            Write-Warning -Message ("Failed to deleting Folder '{0}' [{1}]: {2}" -f $path, $errCode, $errMsg)
        }
    }
    elseif (Test-Path $path -PathType Leaf)
    {
        Try {
            Remove-Item -Path $path -Force
            Write-Host ("Shortcut for {0} removed" -f $path)
        } catch {
            $errCode = $_.Exception.HResult
            $errMsg  = $_.Exception.Message
            Write-Warning -Message ("Failed to deleting file '{0}' [{1}]: {2}" -f $path, $errCode, $errMsg)
        }
    }
    else
    {
        Write-Host ("Item '{0}' not found" -f $path)
    }
}

Stop-Transcript
Exit $errCode
# Changelog:
# ----------
#   14/09/2023 - Creacion Script. (Javier Pastor)


$PrinterName   = "NamePrintTest-PRT1"       # Nombre Impresora con el que Aparece en Windows
$PrinterDrv    = "RICOH IM C3000 PCL 6"     # Driver de la Impresora de obtiene del archivo inf de los drivers.
$PrinterIPName = "IP_{0}" -f $namePrint     # Nombre del PuertoIP

$file_log  = "log_{0}_uninstall_config.log" -f $PrinterName

$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch
    {
        $msgErr = "Failed to start $PSCOMMANDPATH"
        Write-Host $msgErr 
        Throw $msgErr
    }
    Exit 1
}

function Write-ProcessOutput {
    param (
        [System.Diagnostics.Process] $process,
        [bool] $isError = $false
    )

    if ($isError) {
        $outputLine = $process.StandardError.ReadLine()
        $color = 'Red'
    } else {
        $outputLine = $process.StandardOutput.ReadLine()
        $color = 'Green'
    }

    if ($null -ne $outputLine) {
        Write-Host $outputLine -ForegroundColor $color
    }
}

Try {
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($PrinterExist) {
        Remove-Printer -Name $PrinterName -Confirm:$false
        Write-Host ("Remove Print - {0} - OK" -f $PrinterName)
    }
}
Catch {
    Write-Host ("Error Remove Print ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}


Try {
    $PrinterDrvExist = Get-PrinterDriver -Name $PrinterDrv -ErrorAction SilentlyContinue
    if ($PrinterDrvExist) {
        Remove-PrinterDriver -Name $PrinterDrv -Confirm:$false
        Write-Host ("Remove Driver - {0} - OK" -f $PrinterDrv)
    }
}
Catch {
    Write-Host ("Error Remove Driver ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}

Try {
    $PrinterPortExist = Get-PrinterPort -Name $PrinterIPName -ErrorAction SilentlyContinue
    if ($PrinterPortExist) {
        Remove-PrinterPort -Name $PrinterIPName -Confirm:$false
        Write-Host ("Remove Port - {0} - OK" -f $PrinterIPName)
    }
}
Catch {
    Write-Host ("Error Remove Port ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}

Stop-Transcript
Exit 0
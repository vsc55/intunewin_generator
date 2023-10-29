# Changelog:
# ----------
#   14/09/2023 - Creacion Script. (Javier Pastor)


$PrinterName   = "NamePrintTest-PRT1"       # Nombre Impresora con el que Aparece en Windows
$PrinterDrv    = "RICOH IM C3000 PCL 6"     # Driver de la Impresora de obtiene del archivo inf de los drivers.
$PrinterIP     = "192.168.0.60"             # IP de la Impresora
$PrinterIPName = "IP_{0}" -f $namePrint     # Nombre del PuertoIP

$file_log  = "log_{0}_reinstall_config.log" -f $PrinterName

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








Try {
    Add-PrinterPort -Name $PrinterIPName -PrinterHostAddress $PrinterIP
    Write-Host ("Install Port - {0} - OK" -f $PrinterIPName)
}
Catch {
    Write-Host ("Error Install Prot ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}


Try {
    Add-PrinterDriver -Name $PrinterDrv
    Write-Host ("Install Driver - {0} - OK" -f $PrinterDrv)
}
Catch {
    Write-Host ("Error Install Driver ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}


Try {
    Add-Printer -Name $PrinterName -DriverName $PrinterDrv -PortName $PrinterIPName
    Write-Host ("Install Printe - {0} - OK" -f $PrinterName)
}
Catch {
    Write-Host ("Error Install Print ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}


Stop-Transcript
Exit 0
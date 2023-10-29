# Changelog:
# ----------
#   14/09/2023 - Creacion Script. (Javier Pastor)


$PrinterName   = "NamePrintTest-PRT1"       # Nombre Impresora con el que Aparece en Windows
$PrinterDrv    = "RICOH IM C3000 PCL 6"     # Driver de la Impresora de obtiene del archivo inf de los drivers.
$PrinterIP     = "192.168.0.60"             # IP de la Impresora
$PrinterIPName = "IP_{0}" -f $namePrint     # Nombre del PuertoIP

$file_log  = "log_{0}_install_config.log" -f $PrinterName

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
    Add-PrinterPort -Name $PrinterIPName -PrinterHostAddress $PrinterIP
    Write-Host ("Install Port - {0} - OK" -f $PrinterIPName)
}
Catch {
    # Write-Host "Error install Port"
    # Write-Host "$($_.Exception.Message)"
    Write-Host ("Error Install Prot ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}


Try {
    Add-PrinterDriver -Name $PrinterDrv
    Write-Host ("Install Driver - {0} - OK" -f $PrinterDrv)
}
Catch {
    # Write-Host "Error install Driver"
    # Write-Host "$($_.Exception.Message)"
    Write-Host ("Error Install Driver ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}


Try {
    Add-Printer -Name $PrinterName -DriverName $PrinterDrv -PortName $PrinterIPName
    Write-Host ("Install Printe - {0} - OK" -f $PrinterName)
}
Catch {
    # Write-Host "Error install Print"
    # Write-Host "$($_.Exception.Message)"
    Write-Host ("Error Install Print ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)
}

Stop-Transcript
Exit 0
# Version 1.0
#
# Changelog:
# ----------
#   Ver 1.0
#   14/09/2023 - Creacion Script. (Javier Pastor)

$LogFileNameGlobal = "log_print_global.log"
$LogFileName       = "log_print_{0}_UnInstall.log"

$ScriptDirectory   = $PSScriptRoot

$LogFilePathGlobal = Join-Path -Path $env:TEMP -ChildPath $LogFileNameGlobal
Start-Transcript -Path $LogFilePathGlobal -Append

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

# Init Vars
$PrinterName   = ""     # Nombre Impresora con el que Aparece en Windows
$PrinterDrv    = ""     # Driver de la Impresora de obtiene del archivo inf de los drivers.
$PrinterIPName = ""     # Nombre del PuertoIP

try {
    $jsonFilePath = Join-Path -Path $ScriptDirectory -ChildPath "info.json"
    $data = Get-Content -Path $jsonFilePath -Raw -ErrorAction Stop | ConvertFrom-Json

    $propertiesToCheck = @("PrinterName", "PrinterDrv")

    $missingProperties = $propertiesToCheck | Where-Object { [string]::IsNullOrEmpty($data.$_) }
    if ($missingProperties.Count -gt 0)
    {
        Write-Host "Error: The following properties are required but missing or empty: $($missingProperties -join ', ')" -ForegroundColor Red
        Stop-Transcript
        Exit 1
    }

    $PrinterName = $data.PrinterName
    $PrinterDrv  = $data.PrinterDrv

    if ($data.PSObject.Properties["PrinterIPName"])
    {
        $PrinterIPName = $data.PrinterIPName
    }
    if ([string]::IsNullOrEmpty($PrinterIPName))
    {
        $PrinterIPName = "IP_{0}" -f $PrinterName
    }
}
catch
{
    Write-Host ("Error read JSON: {0}" -f $_) -ForegroundColor Red
    Stop-Transcript
    Exit 1
}

Stop-Transcript

$LogFileName = $LogFileName -f $PrinterName
$LogFilePath = Join-Path -Path $env:TEMP -ChildPath $LogFileName
Start-Transcript -Path $LogFilePath -Append

$errCode = 0

Try {
    $PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
    if ($PrinterExist) {
        Remove-Printer -Name $PrinterName -Confirm:$false -ErrorAction Stop
        Write-Host ("Remove Print - {0} - OK" -f $PrinterName) -ForegroundColor Green
    }
    else {
        Write-Host ("Warning Remove Print: Print '{0}' Not Detected" -f $PrinterName) -ForegroundColor Yellow
    }
}
Catch
{
    Write-Host ("Error Remove Print ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message) -ForegroundColor Red
    $errCode = 1
}

Try {
    $PrinterDrvExist = Get-PrinterDriver -Name $PrinterDrv -ErrorAction SilentlyContinue
    if ($PrinterDrvExist) {
        Remove-PrinterDriver -Name $PrinterDrv -Confirm:$false -ErrorAction Stop
        Write-Host ("Remove Driver - {0} - OK" -f $PrinterDrv) -ForegroundColor Green
    }
    else {
        Write-Host ("Warning Remove Driver: Driver '{0}' Not Detected" -f $PrinterDrv) -ForegroundColor Yellow
    }
}
Catch {
    Write-Host ("Error Remove Driver ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message) -ForegroundColor Red
    $errCode = 1
}

Try {
    $PrinterPortExist = Get-PrinterPort -Name $PrinterIPName -ErrorAction SilentlyContinue
    if ($PrinterPortExist) {
        Remove-PrinterPort -Name $PrinterIPName -Confirm:$false -ErrorAction Stop
        Write-Host ("Remove Port - {0} - OK" -f $PrinterIPName) -ForegroundColor Green
    }
    else {
        Write-Host ("Warning Remove Port: Port '{0}' Not Detected" -f $PrinterIPName) -ForegroundColor Yellow
    }
}
Catch {
    Write-Host ("Error Remove Port ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message)  -ForegroundColor Red
    $errCode = 1
}

Stop-Transcript
Exit $errCode
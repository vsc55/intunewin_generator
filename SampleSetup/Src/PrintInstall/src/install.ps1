# Changelog:
# ----------
#   14/09/2023 - Creacion Script. (Javier Pastor)


$LogFileNameGlobal = "log_print_global.log"
$LogFileName       = "log_print_{0}_Install.log"

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
$PrinterIP     = ""     # IP de la Impresora
$PrinterIPName = ""     # Nombre del PuertoIP

try {
    $jsonFilePath = Join-Path -Path $ScriptDirectory -ChildPath "info.json"
    $data = Get-Content -Path $jsonFilePath -Raw -ErrorAction Stop | ConvertFrom-Json

    $propertiesToCheck = @("PrinterName", "PrinterDrv", "PrinterIP")

    $missingProperties = $propertiesToCheck | Where-Object { [string]::IsNullOrEmpty($data.$_) }
    if ($missingProperties.Count -gt 0)
    {
        Write-Host "Error: The following properties are required but missing or empty: $($missingProperties -join ', ')" -ForegroundColor Red
        Stop-Transcript
        Exit 1
    }

    $PrinterName = $data.PrinterName
    $PrinterDrv  = $data.PrinterDrv
    $PrinterIP   = $data.PrinterIP

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
    Add-PrinterPort -Name $PrinterIPName -PrinterHostAddress $PrinterIP -ErrorAction Stop
    Write-Host ("Install Port - {0} - OK" -f $PrinterIPName) -ForegroundColor Green
}
Catch {
    if ($_.Exception.HResult -eq "-2146233088") # Skip, el puerto ya existe
    {
        Write-Host ("Warning Install Prot: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
    else
    {
        Write-Host ("Error Install Prot ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message) -ForegroundColor Red
        $errCode = 1
    }
}

if ($errCode -eq "0")
{
    Try {
        Add-PrinterDriver -Name $PrinterDrv -ErrorAction Stop
        Write-Host ("Install Driver - {0} - OK" -f $PrinterDrv) -ForegroundColor Green
    }
    Catch {
        Write-Host ("Error Install Driver ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message) -ForegroundColor Red
        $errCode = 1
    }
}

if ($errCode -eq "0")
{
    Try {
        Add-Printer -Name $PrinterName -DriverName $PrinterDrv -PortName $PrinterIPName -ErrorAction Stop
        Write-Host ("Install Printe - {0} - OK" -f $PrinterName) -ForegroundColor Green
    }
    Catch {
        if ($_.Exception.HResult -eq "-2146233088") # Skip, la impresora ya existe
        {
            Write-Host ("Warning Install Print: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
        else
        {
            Write-Host ("Error Install Print ({0}): {1}" -f $_.Exception.HResult, $_.Exception.Message) -ForegroundColor Red
            $errCode = 1
        }
    }
}

Stop-Transcript
Exit $errCode
# Version: 1.1
#
# Changelog:
# ----------
#   07/08/2023 - Creacion Script. (Javier Pastor)
#   22/08/2023 - Add Suport Multiple Files INF. (Javier Pastor)
#   29/10/2023 - Move config to file info.json. (Javier Pastor)

# Intune Cmd:
# Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\uninstall.ps1
#
# Sample pnputil.exe:
# "C:\Windows\sysnative\pnputil.exe" /delete-driver "C3422WE.inf" /uninstall >> "C:\Windows\Temp\DELL_C3422WE_log.txt"
#


$LogFileNameGlobal = "log_driver_global.log"
$LogFileName       = "log_driver_{0}_UnInstall.log"

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
    Exit
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


# Init Vars
$scriptName = "driversGen"
$infFiles   = @()


# Guarda el valor actual de $ErrorActionPreference
$origlErrorActionPreference = $ErrorActionPreference

# Establece $ErrorActionPreference en "Stop" para que los errores sean terminantes
# Tenemos que usar esto para que Get-Content entre en el catch si el archivo no existe o se produce otro error.
$ErrorActionPreference = "Stop"

try {
    $jsonFilePath = Join-Path -Path $ScriptDirectory -ChildPath "info.json"
    $data = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json

    $scriptName = $data.name
    $infFiles   = $data.files
}
catch
{
    Write-Host ("Error read JSON: {0}" -f $_) -ForegroundColor Red
    Exit 1
}
finally {
    # Restaura el valor original de $ErrorActionPreference
    $ErrorActionPreference = $origlErrorActionPreference
}

Stop-Transcript

$LogFileName = $LogFileName -f $scriptName
$LogFilePath = Join-Path -Path $env:TEMP -ChildPath $LogFileName
Start-Transcript -Path $LogFilePath -Append


$errCode = 0
$errMsg  = ""

foreach ($fileINF in $infFiles)
{
    try
    {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = (Get-Command "pnputil.exe").Source
        $psi.Arguments              = "/delete-driver `"{0}`" /uninstall" -f (Join-Path -Path $ScriptDirectory -ChildPath $fileINF)
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError  = $true
        $psi.UseShellExecute        = $false

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi
        $process.Start() | Out-Null

        while (!$process.HasExited)
        {
            while (!$process.StandardOutput.EndOfStream) { Write-ProcessOutput -process $process -isError $false }
            while (!$process.StandardError.EndOfStream)  { Write-ProcessOutput -process $process -isError $true }
            Start-Sleep -Milliseconds 100
        }

        # Leer los últimos datos después de que el proceso haya terminado
        while ($process.StandardOutput.Peek() -ge 0) { Write-ProcessOutput -process $process -isError $false }
        while ($process.StandardError.Peek() -ge 0)  { Write-ProcessOutput -process $process -isError $true }
        Write-Host ""

        $errCode = $process.ExitCode
        $errMsg  = $process.StandardError
    }
    catch
    {  
        $errCode = $_.Exception.HResult
        $errMsg = $_.Exception.Message
        break
    }

    if ($errCode -eq 0 -or $errCode -eq 259 -or $errCode -eq 3010)
    {
        Write-Host ("UnInstall OK ({0})" -f $errCode)
        $errCode = 0
    }
    else
    {
        Write-Host ("UnInstall Error ({0}): {1}" -f $errCode, $errMsg)
        break
    }
}

Stop-Transcript
Exit $errCode
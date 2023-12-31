﻿# Version: 1.0
#
# Changelog:
# ----------
#   Ver 1.0
#   07/08/2023 - Base Version Software 1.4
#
# Intune Cmd:
#   Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\uninstall.ps1
#
#
# CONFIG: Las opciones están definidas en $propertyMappings con su valor por defecto.
#           << Ejemplo de "config.json" >>
#           {
#               "appName": ".NetFrameWork3.5",
#               "appUninstallPath": "dism.exe",
#               "appUninstallArgs": "/online /Disable-Feature /FeatureName:NetFx3",
#               "appUninstallRemovePost": []
#           }
#
# NOTA: Si el script se ejecuta en un cmd o powershell de 32 bits (SysWOWO64), este
#       se relanzará en modo 64 bits.
#


# Iniciamos Variables
$errCode    = 0
$errMsg     = ""
$appAcction = "Uninstall"   # Definir aquí la acción (Install/Uninstall/etc...)


# Usamos un archivo log global para el proceso de inicialización
$logFileGloabl = Join-Path $env:TEMP "log_intune_global.txt"
Start-Transcript -Path $logFileGloabl -Append


# Cargar el contenido del archivo JSON
$configFile     = "config.json"
$configFilePath = Join-Path $PSScriptRoot $configFile

$jsonConfig     = @{}
if (Test-Path $configFilePath -PathType Leaf)
{
    try
    {
        $jsonConfig = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
    }
    catch
    {
        $errCode     = $_.Exception.HResult
        $errMsg      = $_.Exception.Message
        $errLocation = $_.InvocationInfo.PositionMessage
        Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red
        Exit $errCode
    }
}
else
{
    Write-Host ("File {0} not found. :(" -f $configFile) -ForegroundColor Red
    Exit 1
}

# Definimos las var en blanco
$appName = $appUninstallPath = $appUninstallArgs = $appUninstallRemovePost = $logFilePath = $logFileName = $isOkCleanLog = $isOkRemoveLog = ""

# Definir las propiedades y sus valores por defecto
$propertyMappings = @{
    "appName" = @{
        'valueDefault'   = "AppName"
        'isEmptyDefault' = $true
    }
    "appUninstallPath" = @{
        'valueDefault'   = ""
    }
    "appUninstallArgs" = @{
        'valueDefault'   = ""
    }
    "appUninstallRemovePost" = @{
        'valueDefault'   = @()
        'isEmptyDefault' = $true
    }
    "logFilePath" = @{
        'valueDefault'   = '{{temp}}'
        'isEmptyDefault' = $true
    }
    "logFileName" = @{
        'valueDefault'   = 'log_{{appName}}_process.txt'
        'isEmptyDefault' = $true
    }
    "isOkCleanLog" = @{
        'valueDefault'   = $false
        'isEmptyDefault' = $true
    }
    "isOkRemoveLog" = @{
        'valueDefault'   = $false
        'isEmptyDefault' = $true
    }
}

# Asignar los valores del JSON a las variables correspondientes con valores por defecto
$propertyMappings.GetEnumerator() | ForEach-Object {
    $key   = $_.Key
    $value = if ($jsonConfig.PSObject.Properties.Name -contains $key) { $jsonConfig.$key } else { $_.Value.valueDefault }

    # Verificar si 'isEmptyDefault' está definido y es verdadero
    if ($_.Value.ContainsKey('isEmptyDefault') -and $_.Value.isEmptyDefault -eq $true)
    {
        # Verificar si el valor de $value está vacío
        if ([string]::IsNullOrEmpty($value)) {
            $value = $_.Value.valueDefault
        }
    }

    Set-Variable -Name $key -Value $value
    Write-Host "Read Config: $key => $value"
}

# Plantillas que deseas reemplazar
$templates = @{
    "{{ProgramFiles}}" = @{
        'value'   = $env:ProgramFiles
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    "{{appName}}" = @{
        'value'   = $appName
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    "{{logFileName}}" = @{
        'value'   = $logFileName
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    "{{temp}}" = @{
        'value'   = $env:TEMP
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    "{{scriptPathRoot}}" = @{
        'value'   = $PSScriptRoot
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    "{{userPublic}}" = @{
        'value'   = $env:Public
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    "{{userRoaming}}" = @{
        'value'   = $env:APPDATA
        'replace' = { param($arg_find, $arg_source, $arg_newval) ![string]::IsNullOrEmpty($arg_newval) }
    }
    
    # "{{AnotherTemplate}}" = @{
    #     'value'   = "ReplacementValue"
    #     'replace' = $true
    #      o
    #     'replace' = { param($arg_find, $arg_source, $arg_newval) $true }
    # }
}

# Aplicar las plantillas usando las variables ya definidas
$propertyMappings.GetEnumerator() | ForEach-Object {
    $key       = $_.Key
    $value     = Get-Variable -Name $key -ValueOnly
    $valueOrig = $value
    
    $templates.GetEnumerator() | ForEach-Object {
        $t_Key   = $_.Key
        $t_Value = $_.Value
        if ($value -like "*$t_Key*" -and $t_Value.ContainsKey("value"))
        {
            $arg_find   = $t_key            # Texto a buscar, ejemplo {{logFileName}}
            $arg_source = $value            # Texto origen, ejemplo C:\TEMP\{{logFileName}}
            $arg_newval = $t_Value['value'] # Texto nuevo que se va a usar, ejemplo log.txt
                                            # > Resultado C:\TEMP\log.txt

            if (!$t_Value.ContainsKey("replace") -or ($t_Value.ContainsKey("replace") -and (& $t_Value['replace'] $arg_find $arg_source $arg_newval) -eq $true))
            {
                $value = $value -replace $t_Key, $t_Value.value
            }
        }
    }
    if ($valueOrig -ne $value)
    {
        Set-Variable -Name $key -Value $value
        Write-Host "Final Config: $key => $value"
    }
    else
    {
        Write-Host "Final Config (No Change): $key => $value"
    }
}

# Definimos el Path completo del archivo log.
$logFileNameFull = Join-Path $logFilePath $logFileName
Write-Host "LogFile: $logFileNameFull"



# Detectamos si estamos en modo x86 o x64
If ($ENV:PROCESSOR_ARCHITEW6432 -eq "AMD64") {
    Try {
        Write-Host "Running in x86 mode, reboot in x64 mode..."
        &"$ENV:WINDIR\SysNative\WindowsPowershell\v1.0\PowerShell.exe" -File $PSCOMMANDPATH
    }
    Catch
    {
        $msgErr = "Failed to start $PSCOMMANDPATH"
        $msgErr | Out-File -FilePath $logFileNameFull -Append
        Throw $msgErr
    }
    Exit
}

# Iniciamos captura al archivo log del programa
Stop-Transcript
Start-Transcript -Path $logFileNameFull -Append

function Send-Write-EventLog {
    param (
        [string]$message,
        [int]$eventId = 1000,
        [System.Diagnostics.EventLogEntryType]$entryType = [System.Diagnostics.EventLogEntryType]::Information
    )

    $messageLines = $message -split "`n"
    $eventMessage = $messageLines -join "`r`n"
    
    $colorMapping = @{
        "Error"       = "Red"
        "Warning"     = "Yellow"
        "Information" = "Green"
    }
    $color = $colorMapping[$entryType.ToString()] -as [System.ConsoleColor]
    if ($color -ne $null)
    {
        Write-Host $eventMessage -ForegroundColor $color
    }
    else
    {
        Write-Host $eventMessage
    }

    $formattedMessage = "{0} > {1} - {2}" -f $global:appName, $global:appAcction, $eventMessage
    Write-EventLog -LogName Application -Source Application -EventId $eventId -EntryType $entryType -Message $formattedMessage
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


try
{
    # $ProcessInfo = Start-Process -FilePath $appUninstallPath -ArgumentList $appUninstallArgs -WindowStyle Hidden -RedirectStandardOutput $logFileNameFull -Wait -PassThru
    # $errCode     = $ProcessInfo.ExitCode
    # $errMsg      = $ProcessInfo.StandardError

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $appUninstallPath
    $psi.Arguments              = $appUninstallArgs
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
    $errCode     = $_.Exception.HResult
    $errMsg      = $_.Exception.Message
    $errLocation = $_.InvocationInfo.PositionMessage
    Send-Write-EventLog -entryType Error -message ("{0} {1}" -f $errMsg, $errLocation)
}

if ($errCode -eq 0)
{
    Foreach ($path_remove in $appUninstallRemovePost) {
        Try
        {
            if (Test-Path $path_remove -PathType Container)
            {
                # Remove Folder
                Remove-Item -LiteralPath $path_remove -Force -Recurse
            }
            elseif (Test-Path $path_remove -PathType Leaf)
            {
                # Remove File
                Remove-Item -Path $path_remove -Force
            }
            else
            {
                Write-Host ("Skipped, item [{0}] not exist" -f $path_remove)
                Continue
            }
        }
        catch
        {
            $errCode     = $_.Exception.HResult
            $errMsg      = $_.Exception.Message
            $errLocation = $_.InvocationInfo.PositionMessage
            Write-Host ("Error to remove [{0}] - Code {1}: {2}" -f $path_remove, $errCode, $errMsg)
            Break
        }
        Write-Host ("Item [{0}] removed OK" -f $path_remove)
    }
}

if ($errCode -eq 0)
{
    Send-Write-EventLog -message ("{0} - {1} OK" -f $appName, $appAcction)

    # Eliminar/Vacia archivos log si existen y se configura
    if ($isOkRemoveLog -or $isOkCleanLog)
    {
        $logsToRemoveTruncate = @(
            $logFileGloabl,
            $logFileNameFull
        )
        
        $logsToRemoveTruncate | ForEach-Object {
            $localFileLog = $_
            if (Test-Path $localFileLog -PathType Leaf)
            {
                try
                {
                    if ($isOkRemoveLog)
                    {
                        Remove-Item -Path $localFileLog -Force
                    }
                    elseif ($isOkCleanLog)
                    {
                        Clear-Content -Path $localFileLog
                    }
                }
                catch
                {
                    $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    Send-Write-EventLog -entryType Error -message ("[{0}] - {1} {2}" -f $errCode, $errMsg, $errLocation)

                    # Lo dejamos otra vez a 0 para no retornar error en la ejecucion general
                    $errCode = 0
                    $errMsg  = ""
                }
            }
        }
    }
}
else
{
    Send-Write-EventLog -entryType Error -message ("{0} - {1} Error ({2}): {3}" -f $appName, $appAcction, $errCode, $errMsg)
}
Stop-Transcript

Exit $errCode
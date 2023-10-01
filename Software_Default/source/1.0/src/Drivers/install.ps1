# Version: 1.1
#
# Changelog:
# ----------
#   04/08/2023 - Creacion Script. (Javier Pastor)
#   22/08/2023 - Add Suport Multiple Files INF. (Javier Pastor)

# Intune Cmd:
# Powershell.exe -NoProfile -ExecutionPolicy ByPass -File .\install.ps1
#
# Ejemplo pnputil.exe:
# "C:\Windows\System32\pnputil.exe" /add-driver "C3422WE.inf" /install >> "C:\Windows\Temp\DELL_C3422WE_log.txt"
#

$script_name ="RICOH_IMC3000A_Install"

$files_INF = @(
    "oemsetup.inf",
    "RPRNUT.inf"
)

$file_log  = "log_driver_{0}.txt" -f $script_name
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

$errCode = 0
$errMsg  = ""

$ScriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($fileINF in $files_INF) {
    try
    {
        $processArgs = "/add-driver `"{0}`" /install" -f (Join-Path $ScriptDirectory $fileINF)

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = (Get-Command "pnputil.exe").Source
        $psi.Arguments              = $processArgs
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

        # $ProcessInfo = Start-Process -FilePath $pnputilPath -ArgumentList $processArgs -WindowStyle Hidden -RedirectStandardOutput $LogFilePath -Wait -PassThru
        # $errCode = $ProcessInfo.ExitCode
        # $errMsg  = $ProcessInfo.StandardError
    }
    catch
    {  
        $errCode = $_.Exception.HResult
        $errMsg = $_.Exception.Message
        break
    }

    if ($errCode -eq 0 -or $errCode -eq 259 -or $errCode -eq 3010)
    {
        Write-Host ("Install OK ({0})" -f $errCode)
        $errCode = 0
    }
    else
    {
        Write-Host ("Error ({0}): {1}" -f $errCode, $errMsg)
        break
    }
}

Stop-Transcript
Exit $errCode
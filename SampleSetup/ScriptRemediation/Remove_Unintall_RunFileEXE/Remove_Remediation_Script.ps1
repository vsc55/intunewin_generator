# Name of the app to uninstall
$script_name ="Remove_7-Zip"

# Name of the app to uninstall
$AppExeRun  = "%ProgramFiles%\7-Zip\Uninstall.exe"
$AppExeArgs = "/S"


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

$errCode     = 0
$errMsg      = ""
$file_log    = "log_remediation_{0}.txt" -f $script_name
$LogFilePath = Join-Path $env:TEMP $file_log
Start-Transcript -Path $LogFilePath -Append

if (Test-Path -Path $CmdUnintall -PathType Leaf)
{
    Write-Host -Object "Attempting to uninstall..."
    Try 
    {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = $AppExeRun
        $psi.Arguments              = $AppExeArgs
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

        Write-Host -Object "Successfully uninstalled."
    }
    Catch
    {
        $errCode = $_.Exception.HResult
        $errMsg  = $_.Exception.Message
        Write-Warning -Message ("Failed to uninstall - ({1}): {2}" -f $errCode, $errMsg )
    }
}
else
{
    Write-Host "Skip, Software not detected!"
}

Stop-Transcript
Exit $errCode
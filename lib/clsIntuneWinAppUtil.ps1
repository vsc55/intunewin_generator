if (-not (Test-Path Function:\CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    return
}


class intuneWinAppUtil {
    [string]$intuneWinAppUtilPath = ""

    [bool]$catInclude = $false
    [string]$catPath = ""

    [string]$outPath = ""

    [string]$sourcePath = ""
    [string]$cmdInstall = ""

    [string]$errMsg  = ""
    [string]$errCode = ""

    intuneWinAppUtil([string] $intuneWinAppUtilPath) {
        $this.intuneWinAppUtilPath = $intuneWinAppUtilPath
    }


    [string] GetNameFileIntuneWin() {
        return [System.IO.Path]::GetFileNameWithoutExtension($this.cmdInstall) + ".intunewin"
    }

    [string] GetPathFileIntuneWin() {
        return (Join-Path $this.outPath $this.GetNameFileIntuneWin())
    }

    [bool] isIntuneWinFileExist(){
        return (Test-Path -Path $this.GetPathFileIntuneWin() -Type Leaf) 
    }

    [bool] DeleteIntuneWinFile([bool] $ask = $true, [bool] $showMsg = $true) {

        if ($this.isIntuneWinFileExist())
        {
            $nameFile = $this.GetNameFileIntuneWin()
            $pathFile = $this.GetPathFileIntuneWin()

            if ($ask)
            {
                $showMsg = $true
                Write-Host ("El archivo '{0}' ya existe!" -f $nameFile) -ForegroundColor Yellow

                $choice = Read-Host "Deseas borrarlo? (Y/N)"
                if (!($choice -eq "Y" -or $choice -eq "y"))
                {
                    Write-Host "Proceso abortado." -ForegroundColor Yellow
                    return $false
                }
            }
            try
            {
                Remove-Item -Path $pathFile -Force
                if ($showMsg) {
                    Write-Host ("Archivo '{0}' borrado." -f $nameFile) -ForegroundColor Green
                }
            }
            catch
            {
                if ($showMsg) {
                    Write-Host "Error al borrar el archivo: $_" -ForegroundColor Red
                }
                return $false
            }
        }
        return $true
    }

    [bool] CreateIntuneWinFile() {

        if (-not $this.DeleteIntuneWinFile($true, $true))
        {
            return $false
        }
        try {
            # Clear-Host
            Write-Host "Iniciado proceso de compilacion..."
            
            $processArgs = "-c `"{0}`" -s `"{1}`" -o `"{2}`"" -f $this.sourcePath, $this.cmdInstall, $this.outPath
            if ($this.catInclude)
            {
                # -a : Los archivos de catálogo (.cat) son archivos de firma digital que se utilizan para 
                # verificar la autenticidad e integridad de los archivos ejecutables.
                $processArgs += " -a `"{1}`"" -f $this.catPath
            }

            
            # $ProcessInfo = Start-Process -FilePath $this.intuneWinAppUtilPath -ArgumentList $processArgs -Wait -PassThru

            
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $this.intuneWinAppUtilPath
            $psi.Arguments = $processArgs
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.RedirectStandardInput = $true
            $psi.UseShellExecute = $false
            $psi.CreateNoWindow = $true

            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $psi
            $process.Start() | Out-Null

            # $process.StandardInput.WriteLine("Y")

            $output = $process.StandardOutput.ReadToEnd()
            $errorOutput = $process.StandardError.ReadToEnd()

            $process.WaitForExit()
            $this.errCode     = $process.ExitCode
            $this.errMsg      = $process.StandardError


            Write-Host ""
            Write-Host $output

            if ($this.errCode -ne 0)
            {
                Write-Host ("El proceso se ha completado con un codigo de salida de ({0}). Ocurrio un error personalizado." -f $this.errCode) -ForegroundColor Red
                Write-Host $errorOutput -ForegroundColor Red
                return $false
            }
            return $true
        }
        catch {
            $this.errCode = $_.Exception.HResult
            $this.errMsg  = $_.Exception.Message

            Write-Host ("Ocurrio un error al ejecutar el proceso: {0}" -f $this.errMsg) -ForegroundColor Red
            if ($_.Exception.InnerException)
            {
                Write-Host ("Detalles del error interno: {0}" -f $_.Exception.InnerException.Message) -ForegroundColor Red
            }
            return $false
        }
    }
}









# $pool = [FileDownloaderPool]::new()


# $intuneWinAppUtilFileExe     = "IntuneWinAppUtil.exe"
# $intuneWinAppUtilUrlDownload = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/$intuneWinAppUtilFileExe"
# $intuneWinAppUtilUrlGitHub   = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
# $intuneWinAppUtilPath        = Join-Path $binPathFull $intuneWinAppUtilFileExe

# # Crear un descargador en espera
# $downloader1 = $pool.CreateDownloader($intuneWinAppUtilUrlDownload, $intuneWinAppUtilPath, $intuneWinAppUtilFileExe)


# $pool.StartAllDownloads()

# while ($pool.HasPendingDownloads)
# {
#     $pool.StartAllDownloads()
#     $pool.ShowDownloadStatus()
#     Start-Sleep -Seconds 1
# }
# $pool.ShowDownloadStatus()

# exit;











# $intuneWinAppUtilFileExe     = "IntuneWinAppUtil.exe"
# $intuneWinAppUtilUrlDownload = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/$intuneWinAppUtilFileExe"
# $intuneWinAppUtilUrlGitHub   = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
# $intuneWinAppUtilPath        = Join-Path $binPathFull $intuneWinAppUtilFileExe

# $downloader = [FileDownloader]::new()
# $downloadResult = $downloader.DownloadFile($intuneWinAppUtilUrlDownload, $intuneWinAppUtilPath, $intuneWinAppUtilFileExe, $true)
# if (-not $downloadResult)
# {
#     Write-Host ""
#     Write-Host "Puedes descargarlo manualmente de: $intuneWinAppUtilUrlGitHub" -ForegroundColor Blue
#     Write-Host ""
#     exit
# }
# Remove-Variable -Name "downloader" -Scope Global


# return



# $intuneWinAppUtilFileExe     = "IntuneWinAppUtil.exe"
# $intuneWinAppUtilUrlDownload = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/$intuneWinAppUtilFileExe"
# $intuneWinAppUtilUrlGitHub   = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"

# $intuneWinAppUtilPath = Join-Path $binPathFull $intuneWinAppUtilFileExe
# if (-not (Test-Path -Path $intuneWinAppUtilPath -PathType Leaf))
# {
#     Write-Host "Descargando $intuneWinAppUtilFileExe..."
#     try
#     {
#         Invoke-WebRequest -Uri $intuneWinAppUtilUrlDownload -OutFile $intuneWinAppUtilPath -ErrorAction Stop
#         Write-Host "Descarga OK!" -ForegroundColor Green
#     }
#     catch
#     {
#         Write-Host "Error al descargar $intuneWinAppUtilFileExe desde el URL: $intuneWinAppUtilUrlDownload" -ForegroundColor Red
#         Write-Host "Detalles del error > $($_.Exception.Message)" -ForegroundColor Red
        
#     }
# }
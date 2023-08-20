if (($null -eq $function:CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    Exit 1
}

Import-Module .\clsFileDownloader.ps1

class FileDownloaderPool {
    [FileDownloader[]] $downloaders      = @()
    
    [void] StartDownloadInBackground([FileDownloader]$newDownloader) {
        
    }

    [void] RemoveErrorDownloads() {
        $this.RemoveDownloadsByStatus([FileDownloaderStatus]::Error)
    }

    [void] RemoveCompletedDownloads() {
        $this.RemoveDownloadsByStatus([FileDownloaderStatus]::Completed)
    }

    [void] RemoveDownloadsByStatus([FileDownloaderStatus] $status) {
        $downloadersToRemove = $this.downloaders | Where-Object { $_.GetStatus() -eq $status }
        foreach ($downloader in $downloadersToRemove) {
            $this.downloaders.Remove($downloader)
        }
    }

    [void] StartPendingDownloadsInBackground() {
        $pendingDownloaders = $this.GetDownloadersByStatus([FileDownloaderStatus]::Pending)
        foreach ($downloader in $pendingDownloaders) {
            $this.StartDownloadInBackground($downloader)
        }
    }

    [void] StartAllDownloads() {
        $pendingDownloaders = $this.GetDownloadersByStatus([FileDownloaderStatus]::Pending)
        foreach ($downloader in $pendingDownloaders) {
            $downloader.StartDownload()
        }
    }

 


    [void] WaitAll() {
        $this.downloaders | ForEach-Object {
            # $_.DownloadThread.Join()

            # esto
            $_.Wait()
            # o esto otro
            if ($_.job -ne $null) {
                Wait-Job -Job $_.job
            }

        }
    }

    [FileDownloader] CreateDownloader([string]$url, [string]$localPath, [string]$fileName, [bool]$autoStartDownload = $true) {

        # $newDownloader = [FileDownloader]::new()
        # $newDownloader.url = $url
        # $newDownloader.localPath = $localPath
        # $newDownloader.fileName = $fileName
        # if (-not $autoStartDownload) {
        # }

        $newDownloader = [FileDownloader]::new()
        $newDownloader.showMsg = $false
        $newDownloader.runBackGroundMode = $true
        $newDownloader.overWrite = $true
        $newDownloader.DownloadFile($url, $localPath, $fileName, $false)
        $this.downloaders += $newDownloader

        if ($autoStartDownload) {
            # $this.StartDownloadInBackground($newDownloader)
            # $newDownloader.StartDownload()
        }

        return $newDownloader
    }

    [FileDownloader] GetDownloaderById([string]$id) {
        return $this.downloaders | Where-Object { $_.id -eq $id }
    }

    [FileDownloader[]] GetDownloadersByStatus([FileDownloaderStatus] $status) {
        return $this.downloaders | Where-Object { $_.GetStatus() -eq $status }
    }

    [bool] HasPendingDownloads() {
        $count = ($this.downloaders | Where-Object { $_.GetStatus() -eq [FileDownloaderStatus]::Pending -or $_.GetStatus() -eq [FileDownloaderStatus]::Downloading } | Select-Object -First 1).Count
        if ($count -eq 0) {
            return $false
        }
        return $true;
    }

    [int] CountDownloaders() {
        return $this.downloaders.Count
    }

    [int] CountDownloadersByStatus([FileDownloaderStatus] $status) {
        return ($this.GetDownloadersByStatus($status)).Count
    }

    [int] CountDownloadersByStatusStr([string] $status) {
        return ($this.downloaders | Where-Object { $_.GetStatusStr() -eq $status }).Count
    }

    [void] ShowDownloadStatus() {
        Clear-Host
        Write-Host "Estado de las descargas:" -ForegroundColor Cyan
        Write-Host ""

        if ($this.CountDownloaders() -eq 0) {
            Write-Host "No hay descargas." -ForegroundColor Yellow
            return
        }

        $this.downloaders | ForEach-Object {
            $id           = $_.GetID()
            $fileName     = $_.GetFileName()
            $status       = $_.GetStatus()
            $statusColor  = $_.GetStatusColor()
            $statusString = $_.GetStatusStr()

            if ($status  -eq [FileDownloaderStatus]::Downloading)
            {
                $progress = $_.GetDownloadProgress()
                $remaining = $_.GetEstimatedTimeRemaining()
                $speed = $_.GetDownloadSpeed()
                if (-not $progress -or $progress.Length -eq 0)
                {
                    $progress = "?"
                }
                if (-not $remaining)
                {
                    $progress = "?"
                }
                Write-Host ("Downloader ID: {0}, File: {1}, Status: {2} - Progress: {3}% - Remaining: {4} - Speed: {5}" -f $id, $fileName, $statusString, $progress, $remaining, $speed) -ForegroundColor $statusColor
            }
            else {
                Write-Host ("Downloader ID: {0}, File: {1}, Status: {2}" -f $id, $fileName, $statusString) -ForegroundColor $statusColor
            }

            if ($status -eq [FileDownloaderStatus]::Error)
            {
                Write-Host ("   >>> ({0}): {1}" -f $_.errorCode, $_.errorMessage) -ForegroundColor Red
                Write-Host ""
                Write-Host "*** Info Error ***" -ForegroundColor Red
                Write-Host ("{0}" -f $_.errorPosition) -ForegroundColor Red
                Write-Host "*** Info Error ***" -ForegroundColor Red
                Write-Host ""
            }
        }

        # Write-Host ""

        # $titulos = @{}
        # $colores = @{}

        # $enumFields = [FileDownloaderStatus].GetFields('Public,Static')
        # $ii = 0
        # foreach ($field in $enumFields) {
        #     if ($ii -eq 0)
        #     {
        #         $titulos += "Resumen - "
        #         $colores += "White"
        #     }
        #     if ($field.FieldType -eq [FileDownloaderStatus])
        #     {
        #         $iStatus = [FileDownloaderStatus]::$($field.Name)
        #         $iCount = $this.CountDownloadersByStatus($iStatus)

        #         if ($ii -eq $enumFields.Count) {
        #             $titulos += "Error({0})" -f $iCount
        #         }
        #         else {
        #             $titulos += "Error({0}), " -f $iCount
        #         }

        #         $colores  += $this.GetStatusColorByArg($iStatus)

        #     }
        #     $ii ++
        # }

        # Write-Color @titulos -Color @colores








        # $erroredCount     = $this.CountDownloadersByStatus([FileDownloaderStatus]::Error)
        # $pendingCount     = $this.CountDownloadersByStatus([FileDownloaderStatus]::Pending)
        # $downloadingCount = $this.CountDownloadersByStatus([FileDownloaderStatus]::Downloading)
        # $completedCount   = $this.CountDownloadersByStatus([FileDownloaderStatus]::Completed)

        # $erroredColor     = $this.GetStatusColorByArg([FileDownloaderStatus]::Error)
        # $pendingColor     = $this.GetStatusColorByArg([FileDownloaderStatus]::Pending)
        # $downloadingColor = $this.GetStatusColorByArg([FileDownloaderStatus]::Downloading)
        # $completedColor   = $this.GetStatusColorByArg([FileDownloaderStatus]::Completed)
        

        # # Write-Host ("Resumen - Error({0}), Pendiente({1}), Descargando({2}), Completado({3})" -f $erroredCount, $pendingCount, $downloadingCount, $completedCount)
        # Write-Host ("Resumen - Error({0}), Pendiente({1}), Descargando({2}), Completado({3})" -f $erroredCount, $pendingCount, $downloadingCount, $completedCount) -ForegroundColor $erroredColor, $pendingColor, $downloadingColor, $completedColor


        
        # Write-Host ("Resumen - Error({0}), Pendiente({1}), Descargando({2}), Completado({3})" -f $erroredCount, $pendingCount, $downloadingCount, $completedCount) -ForegroundColor White
        # Write-Host ("Error({0}), Pendiente({1}), Descargando({2}), Completado({3})" -f $erroredCount, $pendingCount, $downloadingCount, $completedCount) -ForegroundColor $erroredColor, $pendingColor, $downloadingColor, $completedColor




        # [string] GetStatusStr(){
        #     $status_str = switch ($this.GetStatus()) {
        #         [FileDownloaderStatus]::Pending { "Pendiente" }
        #         [FileDownloaderStatus]::Downloading { "Descargando" }
        #         [FileDownloaderStatus]::Completed { "Completada" }
        #         [FileDownloaderStatus]::Error { "Error" }
        #         default { "Desconocido" }
        #     }
        #     return $status_str
        # }


    }
}





# # Ejemplo de uso:
# $pool = [FileDownloaderPool]::new()

# $intuneWinAppUtilFileExe = "IntuneWinAppUtil.exe"
# $intuneWinAppUtilUrlDownload = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/$intuneWinAppUtilFileExe"
# $localPath = "C:\temp"

# # Crear un descargador en espera
# $downloader1 = $pool.CreateDownloader($intuneWinAppUtilUrlDownload, $localPath, $intuneWinAppUtilFileExe, $false)

# # Crear un descargador y comenzar la descarga inmediatamente
# $downloader2 = $pool.CreateDownloader($intuneWinAppUtilUrlDownload, $localPath, $intuneWinAppUtilFileExe, $true)

# # Iniciar todas las descargas en el pool
# $pool.StartAllDownloads()

# # Mostrar el estado de todos los descargadores en el pool
# $pool.ShowDownloadStatus()
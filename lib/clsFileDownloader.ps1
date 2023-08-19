enum FileDownloaderStatus {
    Pending
    Downloading
    Completed
    Error
}

class FileDownloader {
    [string]$id                   = [Guid]::NewGuid().ToString()
    [string]$url                  = ""
    [string]$localPath            = ""
    [string]$fileName             = ""
    [bool]$showMsg                = $true
    [int]$errorCode               = 0
    [string]$errorMessage         = ""
    [string]$errorPosition        = ""
    [FileDownloaderStatus]$status = [FileDownloaderStatus]::Pending
    [bool]$runBackGroundMode      = $false
    [bool]$overWrite              = $false

    [DateTime] $StartTime
    [long] $totalFileSize         = -1

    [string]$result               = @{}


    [System.Collections.Queue] $jobQueue = [System.Collections.Queue]::new()
    [System.Management.Automation.Job]$job

    # [int] $Progress = 0
    # [bool] $IsCancelled = $false
    # [System.Net.WebRequest] $WebRequest
    # [System.Net.WebResponse] $WebResponse
    # [System.Threading.ManualResetEvent] $DownloadCompletedEvent


    [string] GetID(){
        return $this.id
    }

    [FileDownloaderStatus] GetStatus() {
        return $this.status
    }

    [string] GetStatusStr(){
        $status_srt  = $this.GetStatus()
        $data_return = ""
    
        if ($status_srt -eq [FileDownloaderStatus]::Pending) {
            $data_return = "Pendiente"
        }
        elseif ($status_srt -eq [FileDownloaderStatus]::Downloading) {
            $data_return = "Descargando"
        }
        elseif ($status_srt -eq [FileDownloaderStatus]::Completed) {
            $data_return = "Completada"
        }
        elseif ($status_srt -eq [FileDownloaderStatus]::Error) {
            $data_return = "Error"
        }
        else {
            $data_return = "Desconocido"
        }
        return $data_return
    }

    [string] GetStatusColor() {
        return $this.GetStatusColorByArg($this.GetStatus())
    }

    [string] GetStatusColorByArg([FileDownloaderStatus] $statusColor) {
        $statusColorStr = ""
        if ($statusColor -eq [FileDownloaderStatus]::Pending) {
            $statusColorStr = "Gray"
        }
        elseif ($statusColor -eq [FileDownloaderStatus]::Downloading) {
            $statusColorStr = "Yellow"
        }
        elseif ($statusColor -eq [FileDownloaderStatus]::Completed) {
            $statusColorStr = "Green"
        }
        elseif ($statusColor -eq [FileDownloaderStatus]::Error) {
            $statusColorStr = "Red"
        }
        else {
            $statusColorStr = "White"
        }
        return $statusColorStr
    }

    [string] GetUrl() {
        return $this.url
    }
    
    [string] GetFileName() {
        return $this.fileName
    }

    [string] GetLocalPath() {
        return $this.localPath
    }

    [bool] DownloadFile([string]$url, [string]$localPath, [string]$fileName, [bool]$autoStartDownload = $true) {
        $this.url       = $url
        $this.localPath = $localPath
        $this.fileName  = $fileName

        if ($autoStartDownload)
        {
            return $this.StartDownload();
        }
        return $null
    } 

    [bool] StartDownload() {
        $status_return = $true

        if ($this.GetStatus() -eq [FileDownloaderStatus]::Completed) {
            return $true;
        }
        elseif ($this.GetStatus() -eq [FileDownloaderStatus]::Error) {
            return $false;
        }

        if ($this.isFileLocalExists() -and -not $this.overWrite)
        {
            $this.WriteMessage(("El archivo '{0}' ya existe en la ubicación '{1}'." -f $this.GetFileName(), $this.GetLocalPath()), "Yellow")
        }
        else
        {
            $this.status = [FileDownloaderStatus]::Downloading

            $this.StartTime = Get-Date
            $this.UpdateSizeFileOnline()

            if ($this.runBackGroundMode)
            {
                # $this.DownloadCompletedEvent = [System.Threading.ManualResetEvent]::new($false)
                $this.StartDownloadInBackground()
                return $null
            }
            try
            {
                $this.WriteMessage(("Descargando '{0}'..." -f $this.GetFileName()), "White")
                Invoke-WebRequest -Uri $this.GetUrl() -OutFile $this.GetLocalPath() -ErrorAction Stop   
                $this.WriteMessage(("Descarga de '{0}' completada - OK!" -f $this.GetFileName()), "Green")
            }
            catch
            {
                $this.errorCode     = $_.Exception.HResult
                $this.errorMessage  = $_.Exception.Message
                $this.errorPosition = $_.InvocationInfo.PositionMessage

                $this.WriteMessage(("Error al descargar '{0}' desde el URL: {1}" -f $this.GetFileName(), $this.GetUrl()), "Red")
                $this.WriteMessage(("Detalles del error > {0}" -f $this.errorMessage), "Red")
                $status_return = $false
            }
        }
        
        if ($status_return)
        {
            $this.status = [FileDownloaderStatus]::Completed
        }
        else {
            $this.status = [FileDownloaderStatus]::Error
        }
        return $status_return
    }

    [bool] isFileLocalExists() {
        return Test-Path -Path $this.GetLocalPath() -PathType Leaf
    }

    [void] WriteMessage([string] $message, [string] $color = $null) {
        if ($this.showMsg)
        {
            if ($color) { Write-Host $message -ForegroundColor $color }
            else        { Write-Host $message }
        }
    }


    [void] Wait() {
        # $this.jobQueue | ForEach-Object {
        #     $job = $_
        #     $job | Wait-Job
        #     $this.jobQueue.Dequeue()
        # }
    
        if ($this.job -ne $null) {
            Wait-Job -Job $this.job
        }
    
    }



    # [void] ShowDownloadStatus() {
    #     # Mostrar el estado actual de las descargas en la cola de trabajos
    #     $jobs = Get-Job -State Running | Where-Object { $_.Name -match 'DownloaderJob' }
    #     foreach ($job in $jobs) {
    #         $downloader = $this.downloaders | Where-Object { $_.GetID() -eq $job.Name }
    #         $downloader.ShowDownloadStatus()
    #     }
    # }

    [void] UpdateSizeFileOnline() {
        $this.totalFileSize = $this.GetSizeFileUrl($this.GetUrl())
    }

    [long] GetSizeFileUrl([string] $url)
    {
        $data_return = -1
        if ($url -and $url.Length -gt 0)
        {
            $webRequest = [System.Net.WebRequest]::Create($url)
            $webRequest.Method = "HEAD"

            try
            {
                $webResponse = $webRequest.GetResponse()
                if ($webResponse.StatusCode -eq [System.Net.HttpStatusCode]::OK)
                {
                    $data_return = [long]$webResponse.Headers['Content-Length']
                }
                else
                {
                    # Write-Host "La URL devuelve un código de estado no válido: $($webResponse.StatusCode)"
                }
                
                $webResponse.Close()
            }
            catch
            {
                # Write-Host "Error al obtener información del encabezado HEAD: $($_.Exception.Message)"
            }
        }
        return $data_return
    }

    [void] StartDownloadInBackground() {

        if ($this.overWrite -and (Test-Path $this.GetLocalPath() -PathType Leaf))
        {
            Remove-Item $this.GetLocalPath() -Force
        }





        # $invokeWebParams = @{
        #     Uri = $this.GetUrl()
        #     OutFile = $this.GetLocalPath()
        # }
       

        # $this.job = Start-ThreadJob -ScriptBlock {
        #     # Invoke-WebRequest @Using:invokeWebParams -UseBasicParsing
        #     @Using:this.result.Status = $null
        #     try
        #     {
        #         # $null = Invoke-WebRequest @params -ErrorAction Stop
        #         Invoke-WebRequest @Using:invokeWebParams -UseBasicParsing -ErrorAction Stop
        #         @Using:this.result.Status = $true
        #     }
        #     catch
        #     {
        #         @Using:this.result.Status        = $false
        #         @Using:this.result.ErrorCode     = $_.Exception.HResult
        #         @Using:this.result.ErrorMessage  = $_.Exception.Message
        #         @Using:this.result.ErrorPosition = $_.InvocationInfo.PositionMessage
        #     }
        # }
         
        # Write-Host "Successfully invoked $functionUrl"
         
        # while ($job.State -eq "NotStarted") {
        #     Write-Host "Waiting 10 seconds for the job to start"
        #     Start-Sleep -Seconds 10 
        # }








        $argsJob = @{
            Uri = $this.GetUrl()
            OutFile = $this.GetLocalPath()
        }
        $codeJob = {
            param ($params)
            $result = @{}
            $result.Status = $true
            try
            {
                $null = Invoke-WebRequest @params -ErrorAction Stop
            }
            catch
            {
                $result.Status        = $false
                $result.ErrorCode     = $_.Exception.HResult
                $result.ErrorMessage  = $_.Exception.Message
                $result.ErrorPosition = $_.InvocationInfo.PositionMessage
            }
            return $result
        }
        $this.job = Start-Job -Name $this.GetID() -ScriptBlock $codeJob -ArgumentList $argsJob

        $eventIdentifier = "JobStateChanged_$($this.job.Id)"
        $eventActionJob = {
            param ($sender, $eventArgs)
            
            $jobState = $eventArgs.JobStateInfo.State
            if ($jobState -eq [System.Management.Automation.JobState]::Completed)
            {
                $result = Receive-Job -Job $sender
                Write-Host "El trabajo $($sender.Id) ha sido completado. Resultado: $($result -join ', ')"
                
                # Realizar acciones adicionales cuando el trabajo está completado
                Unregister-Event -SourceIdentifier $eventIdentifier
                # @Using:this.jobQueue.Dequeue()
                # $job | Remove-Job
            }
            else
            {
                Write-Host "El estado del trabajo $($sender.Id) cambia a ($jobState.ToString())"
            }
            Pause
        }
        Register-ObjectEvent -InputObject $this.job -EventName 'StateChanged' -SourceIdentifier $eventIdentifier -Action $eventActionJob
        # $this.jobQueue.Enqueue($job)















          # $localPathSave = $this.GetLocalPath()
        # if ($this.overWrite -and (Test-Path $localPathSave -PathType Leaf))
        # {
        #     Remove-Item $localPathSave -Force
        # }
        # $this.WebRequest = [System.Net.WebRequest]::Create($this.Url)
        # $this.WebRequest.Method = 'GET'

        # $this.WebResponse = $this.WebRequest.GetResponse()
        # $contentLength = [long]$this.WebResponse.Headers['Content-Length']

        # $output = [System.IO.File]::OpenWrite($localPathSave)
        # $inputStream = $this.WebResponse.GetResponseStream()
        # $bufferSize = 4096
        # $buffer = New-Object byte[] $bufferSize
        # $totalBytesRead = 0

        # $this.DownloadCompletedEvent.Reset()

        # $progressEvent = Register-ObjectEvent -InputObject $this.WebRequest -EventName 'DownloadProgressChanged' -Action {
        #     param($sender, $eventArgs)
        #     $this.Progress = [math]::Round(($eventArgs.BytesReceived / $contentLength) * 100)
        # }

        # while (($bytesRead = $inputStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
        #     if ($this.IsCancelled) {
        #         break
        #     }
        #     $output.Write($buffer, 0, $bytesRead)
        #     $totalBytesRead += $bytesRead
        # }

        # $output.Close()
        # $inputStream.Close()
        # $this.WebResponse.Close()

        # $this.DownloadCompletedEvent.Set()

        # Unregister-Event -SourceIdentifier $progressEvent.Name
        # $progressEvent.Action = $null

        # if ($this.IsCancelled) {
        #     Remove-Item $this.LocalPath
        # }








        # Ejemplo 1
        # Registrar el evento StateChanged en el trabajo
        # Register-ObjectEvent -InputObject $job -EventName StateChanged -SourceIdentifier "JobStateChangedEvent" -Action {
        #     $eventArgs = $EventArgs
        #     $job = $eventArgs.SourceObject
        #     Write-Host ("Job '{0}' cambió de estado a '{1}'" -f $job.Name, $eventArgs.JobStateInfo.State)
        # }



        # Ejemplo 2
        # $event = Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
        #     if ($Event.SourceEventArgs.NewState -eq 'Completed') {
        #         $completedJob = $Event.SourceObject
        #         # Realiza la lógica para manejar el trabajo completado aquí
        #         # Por ejemplo, podrías eliminarlo de la cola o realizar otras acciones necesarias
                
        #         $jobQueue.Remove($completedJob)
                
        #         # Eliminar el evento
        #         Unregister-Event -SourceIdentifier $Event.Name
        #     }
        # }
    }

    [int] GetDownloadProgress() {
        $data_return = $null
        # if ($this.WebResponse -and $null -ne $this.WebResponse.Headers['Content-Length'])
        # {
        #     $contentLength = [long]$this.WebResponse.Headers['Content-Length']
        #     $data_return   = [math]::Round(($this.TotalBytesRead / $contentLength) * 100)
        # }
        if ($this.GetStatus() -eq [FileDownloaderStatus]::Downloading)
        {
            if ($this.totalFileSize -ge 0)
            {
                $downloadFileSize = [long](Get-ChildItem $this.GetLocalPath()).Length
                $data_return      = [math]::Round(($downloadFileSize / $this.totalFileSize) * 100)
            }
        }
        return $data_return
    }

    [TimeSpan] GetEstimatedTimeRemaining() {
        $data_return = $null
        if ($this.GetStatus() -eq [FileDownloaderStatus]::Downloading)
        {
            if ($null -ne $this.StartTime -and $this.TotalFileSize -ge 0)
            {
                $currentTime = Get-Date
                $timeElapsed = ($currentTime - $this.StartTime).TotalSeconds
                $bytesDownloaded = (Get-Item $this.LocalPath).Length
                $bytesPerSecond = $bytesDownloaded / $timeElapsed
                $bytesRemaining = $this.TotalFileSize - $bytesDownloaded
                $estimatedTimeRemaining = $bytesRemaining / $bytesPerSecond
    
                $data_return = New-TimeSpan -Seconds $estimatedTimeRemaining   
            }
        }
        return $data_return
    }

    [string] GetDownloadSpeed()
    {
        $data_return = "N/A"
        if ($this.GetStatus() -eq [FileDownloaderStatus]::Downloading)
        {
            if ($null -ne $this.StartTime -and $this.TotalFileSize -ge 0)
            {
                $currentTime  = Get-Date
                $timeElapsed  = ($currentTime - $this.StartTime).TotalSeconds
                $downloadSize = (Get-Item $this.GetLocalPath()).Length
                if ($timeElapsed -gt 0)
                {
                    $downloadSpeed = [double]($downloadSize / $timeElapsed)
                    $data_return   = $this.FormatBytesPerSecond($downloadSpeed)
                }
            }
        }
        return $data_return
    }

    [string] FormatBytesPerSecond([double]$bytesPerSecond) {
        $units = "B/s", "KB/s", "MB/s", "GB/s", "TB/s"
        $index = 0

        while ($bytesPerSecond -ge 1024 -and $index -lt $units.Length - 1) {
            $bytesPerSecond /= 1024
            $index++
        }

        return "{0:N2} {1}" -f $bytesPerSecond, $units[$index]
    }

    # [void] CancelDownload() {
    #     $this.WebRequest.Abort()
    #     $this.IsCancelled = $true
    # }

    # [void] WaitDownloadCompleted() {
    #     $this.DownloadCompletedEvent.WaitOne()
    # }

    [void] WaitForJobs() {
        $this.jobQueue | ForEach-Object {
            $_ | Wait-Job
        }
    }
}
















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
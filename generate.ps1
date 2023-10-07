# **** INIT - Load libs ****
$isLoad    = $true;
$hackCheck = "1984"
$debug     = $false

function CheckHack {
    if ($global:hackCheck -ne "1984") {
        return $false
    }
    return $true
}

function ShowDebugObj {
    param (
        [bool]$pause = $true
    )
    if ($global:debug)
    {
        Write-Host ""
        Write-Host "*** DEBUG ***"
        $global:config.ShowConfig()
        Write-Host ""
        $global:paths.ShowPaths()
        Write-Host "*** DEBUG ***"
        Write-Host ""
        if ($pause) {
            pause
        }
    }
}

$rootPath    = $PSScriptRoot;
$initLibPath = Join-Path $rootPath "lib"
if (-not (Test-Path -Path $initLibPath -PathType Container))
{
    Write-Host "Error: Falta lib!" -ForegroundColor Red
    Exit 1
}

Set-Location -Path $initLibPath

Import-Module .\global.ps1

Set-Location -Path $rootPath

if (-not $isLoad)
{
    Write-Host "Error al cargar libs!" -ForegroundColor Red
    Exit 1
}
# **** END - Load libs ****



# Crear objeto MSIntune
$MSIntune = [intuneWin32AppCustom]::new("")
if ($MSIntune.CheckModulesDeps($true, $false) -eq $false)
{
    Write-Host "Faltan dependencias, se desactiva soporte Intune!!" -ForegroundColor Yellow
    $MSIntune.SetEnabled($false)
    pause
}
else
{
    $TenantID = Read-Host "Enter your TenantID (i.e. - domain.com or domain.onmicrosoft.com)"
    $MSIntune.SetTenantID($TenantID)
    $MSIntune.ConnectMSIntune($true)  | Out-Null
}
Start-Sleep -Seconds 2


# Crear Objetos Globales
$paths = [PathItemPool]::new()
$paths.root = $rootPath

$paths.AddPath("lib", $null, $true) | Out-Null
$paths.AddPath("bin", $null, $true) | Out-Null
$paths.AddPath("software", $null, $true) | Out-Null



$config     = [Config]::new(@{})
$configFile = Join-Path $PSScriptRoot "config.json"

$config.NewConfig("intuneWinAppUtilPath", "") | Out-Null
$config.NewConfig("softName", "") | Out-Null
$config.NewConfig("softPath", "") | Out-Null
$config.NewConfig("softPathSrc", "") | Out-Null
$config.NewConfig("softPathOut", "") | Out-Null
$config.NewConfig("softPathInfo", "") | Out-Null
$config.NewConfig("softPathLogo", "") | Out-Null
$config.NewConfig("softFileLogo", "") | Out-Null
$config.NewConfig("softVerName", "") | Out-Null
$config.NewConfig("softVerPath", "") | Out-Null
$config.NewConfig("softVerPathSrc", "") | Out-Null
$config.NewConfig("softVerPathCat", "") | Out-Null
$config.NewConfig("softVerPathScript", "") | Out-Null
$config.NewConfig("softVerScriptDetection", "") | Out-Null
$config.NewConfig("softCmdInstall", "install.cmd") | Out-Null
$config.NewConfig("intunewinName", "") | Out-Null
$config.NewConfig("intunewinPath", "") | Out-Null
$config.NewConfig("intunewinNameSoftware", "") | Out-Null
$config.NewConfig("intunewinPathSoftware", "") | Out-Null

if (Test-Path $configFile -PathType Leaf)
{
    if ($config.LoadConfig($configFile))
    {
        Write-Host "Configuracion cargada exitosamente." -ForegroundColor Green
    }
    else
    {
        Write-Host "Error al cargar la configuracion." -ForegroundColor Red
        Exit 1
    }
}
else
{
    Write-Host "El archivo de configuracion no existe." -ForegroundColor Yellow
}
Start-Sleep -Seconds 2
Write-Host ""


ShowDebugObj


#  $downloadPool = [FileDownloaderPool]::new()

# Ejemplo Pool
# $intuneWinAppUtilFileExe     = "ubuntu-22.04.3-desktop-amd64.iso"
# $intuneWinAppUtilUrlDownload = "https://mirrors.redparra.com/ubuntureleases/22.04.3/ubuntu-22.04.3-desktop-amd64.iso"
# $intuneWinAppUtilUrlGitHub   = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
# $intuneWinAppUtilPath        = Join-Path $paths.GetPath('bin') $intuneWinAppUtilFileExe

# # Crear un descargador en espera
# $download1 = $downloadPool.CreateDownloader($intuneWinAppUtilUrlDownload, $intuneWinAppUtilPath, $intuneWinAppUtilFileExe, $false)

# do {
#     $downloadPool.ShowDownloadStatus()
#     Write-Host ""
#     $downloadPool.StartAllDownloads()
#     Start-Sleep -Seconds 2
# } while ($downloadPool.HasPendingDownloads)

# Start-Sleep -Seconds 1
# $downloadPool.ShowDownloadStatus()






$intuneWinAppUtilFileExe     = "IntuneWinAppUtil.exe"
$intuneWinAppUtilUrlDownload = "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/$intuneWinAppUtilFileExe"
$intuneWinAppUtilUrlGitHub   = "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool"
$intuneWinAppUtilPath        = $paths.GetPathJoin('bin', $intuneWinAppUtilFileExe)

$downloader = [FileDownloader]::new()
$downloader.DownloadFile($intuneWinAppUtilUrlDownload, $intuneWinAppUtilPath, $intuneWinAppUtilFileExe, $false) | Out-Null
$downloader.showMsg   = $true
$downloader.overWrite = $false
$downloadResult = $downloader.StartDownload()
if (-not $downloadResult)
{
    Write-Host ""
    Write-Host "Puedes descargarlo manualmente de: $intuneWinAppUtilUrlGitHub" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
Remove-Variable -Name "downloader" -Scope Global
$config.SetConfig('intuneWinAppUtilPath', $intuneWinAppUtilPath)
Write-Host ""
Start-Sleep -Seconds 2



do {
    # Reseteamos ajuste a los valores por defecto excepto "intuneWinAppUtilPath".
    # También eliminamos los Paths del soft seleccionado.
    $resetExceptionConfig = @("intuneWinAppUtilPath")
    $config.ResetAllToDefault($resetExceptionConfig)
    $paths.DelPath("source") | Out-Null
    $paths.DelPath("out") | Out-Null
    $paths.DelPath("src") | Out-Null
    $paths.DelPath("cat") | Out-Null
    $paths.DelPath("scripts") | Out-Null    

    

    ShowDebugObj


    $softArgs = @{
        lNames       = (Get-ChildItem -Path $paths.GetPath('software') -Directory | Sort-Object Name)
        title        = "Lista de Software"
        msgEmpty     = "No se ha detectado ningun Software."
        msgSelect    = "Seleccione un Software"
        msgSelectErr = "Algo ha salido mal ya que no se ha seleccionado ningún Software :("
    }
    $tmpSelectedSoftwareName = SelectItemList @softArgs
    if ([string]::IsNullOrEmpty($tmpSelectedSoftwareName))
    {
        exit 1    
    }
    $config.SetConfig("softName", $tmpSelectedSoftwareName)
    $config.SetConfig("softPath", $paths.GetPathJoin('software',  $tmpSelectedSoftwareName))
    Remove-Variable -Name "tmpSelectedSoftwareName" -Scope Global

    $paths.UpdatePath("source", $config.GetConfig("softPath"), $true) | Out-Null
    $paths.UpdatePath("out", $config.GetConfig("softPath"), $true) | Out-Null
    $config.SetConfig("softPathSrc", $paths.GetPath('source'))
    $config.SetConfig("softPathOut", $paths.GetPath('out'))

    Write-Host ("Software seleccionado: {0}" -f $config.GetConfig('softName')) -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 1


    ShowDebugObj


    $verArgs = @{
        lNames       = (Get-ChildItem -Path $config.GetConfig('softPathSrc') -Directory | Sort-Object Name -Descending)
        title        = ("Generar archivo intunewin para [{0}]" -f $config.GetConfig('softName'))
        msgEmpty     = ("No se han detectado versiones para [{0}]" -f $config.GetConfig('softName'))
        msgSelect    = "Seleccione una version"
        msgSelectErr = "Algo ha salido mal ya que no se ha seleccionado ningún Software :("
    }
    $tmpSelectedVersionSoftware = SelectItemList @verArgs
    if ([string]::IsNullOrEmpty($tmpSelectedVersionSoftware))
    {
        continue
        # exit 1
    }
    $config.SetConfig("softVerName", $tmpSelectedVersionSoftware)
    $config.SetConfig("softVerPath", $paths.GetPathJoin('source', $tmpSelectedVersionSoftware))
    Remove-Variable -Name "tmpSelectedVersionSoftware" -Scope Global
    
    $paths.UpdatePath("src", $config.GetConfig("softVerPath"), $true) | Out-Null
    $paths.UpdatePath("cat", $config.GetConfig("softVerPath"), $true) | Out-Null
    $paths.UpdatePath("scripts", $config.GetConfig("softVerPath"), $true) | Out-Null
    $config.SetConfig("softVerPathSrc", (Join-Path $config.GetConfig('softVerPath') "src"))
    $config.SetConfig("softVerPathCat", (Join-Path $config.GetConfig('softVerPath') "cat"))
    $config.SetConfig("softVerPathScript", (Join-Path $config.GetConfig('softVerPath') "scripts"))
    $config.SetConfig("softVerScriptDetection", (Join-Path $config.GetConfig('softVerPathScript') "Detection_Script.ps1"))


    $config.NewConfig("", "") | Out-Null

    Write-Host ("Version seleccionado: {0} - {1}" -f $config.GetConfig('softName'), $config.GetConfig('softVerName')) -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 1


    ShowDebugObj


    $tmpAppCmdInstall = Get-ValidInstallCmd -softCmdInstall $config.GetConfig('softCmdInstall') -softVerPath $config.GetConfig('softVerPathSrc') -validExtensions @(".exe", ".com", ".bat", ".cmd", ".ps1")
    if ([string]::IsNullOrEmpty($tmpAppCmdInstall))
    {
        continue
        # exit 1
    }
    $config.SetConfig('softCmdInstall', $tmpAppCmdInstall)
    Remove-Variable -Name "tmpAppCmdInstall" -Scope Global

    Write-Host ("Script/Programa de Instalacion: {0}" -f $config.GetConfig('softCmdInstall')) -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 1





    Clear-Host
    Write-Host ""
    Write-Host " Resumen:" -ForegroundColor Yellow
    Write-Host ("  - Software: {0}" -f $config.GetConfig('softName')) -ForegroundColor Yellow
    Write-Host ("  - Version : {0}" -f $config.GetConfig('softVerName')) -ForegroundColor Yellow
    Write-Host ""
    Write-Host ("  - Source : {0}" -f $config.GetConfig('softVerPathSrc')) -ForegroundColor Cyan
    Write-Host ("  - Catalog: {0}" -f $config.GetConfig('softVerPathCat')) -ForegroundColor Cyan
    Write-Host ("  - Script : {0}" -f $config.GetConfig('softCmdInstall')) -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  - Salida : {0}" -f $config.GetConfig('softPathOut')) -ForegroundColor Green
    Write-Host ""
    ShowDebugObj -pause $false
    pause




    Write-Host ""
    Clear-Host
    $compileIntuneWin                 = [intuneWinAppUtil]::new($config.GetConfig('intuneWinAppUtilPath'))
    $compileIntuneWin.outPath         = $config.GetConfig('softPathOut')
    $compileIntuneWin.sourcePath      = $config.GetConfig('softVerPathSrc')
    $compileIntuneWin.cmdInstall      = $config.GetConfig('softCmdInstall')
    $compileIntuneWin.softwareName    = $config.GetConfig('softName')
    $compileIntuneWin.softwareVersion = $config.GetConfig('softVerName')
    $compileIntuneWin.catInclude      = $true
    $compileIntuneWin.catPath         = $config.GetConfig('softVerPathCat')

    $config.SetConfig("intunewinName", $compileIntuneWin.GetNameFileIntuneWin())
    $config.SetConfig("intunewinPath", $compileIntuneWin.GetPathFileIntuneWin())
    $config.SetConfig("intunewinNameSoftware", $compileIntuneWin.GetNameFileIntuneWinSoftware())
    $config.SetConfig("intunewinPathSoftware", $compileIntuneWin.GetPathFileIntuneWinSoftware())

    $buildIntunewinFile = $true
    if (Test-Path -Path $config.GetConfig("intunewinPathSoftware") -PathType Leaf)
    {
        $buildIntunewinFile = QueryYesNo -msg ("¿El archivo [{0}] ya se ha procesado queres crearlo de nuevo? (Y/N)" -f $config.GetConfig("intunewinPathSoftware"))
        Write-Host ""
    }
    if ($buildIntunewinFile -eq $true)
    {
        if ($compileIntuneWin.CreateIntuneWinFile()) 
        {
            Write-Host "Proceso de compilacion completado ok." -ForegroundColor Green
            Write-Host ""

            if ($compileIntuneWin.RenameIntuneWinFile())
            {
                Write-Host ("El archivo '{0}' se ha creado correctamente" -f $compileIntuneWin.GetNameFileIntuneWinSoftware()) -ForegroundColor Green
                Invoke-Item -Path $config.GetConfig('softPathOut')
            }
        }
        Write-Host ""
    }


    

    # --- INI --- Seccion Publish App
    if ($MSIntune.GetIsEnabled())
    {
        $queryPublishApp = $false
        # $queryPublishApp = QueryYesNo -msg "You want to Publish the App in Intune?(Y/N) -ForegroundColor Green

        $queryPublishApp = QueryYesNo -msg $(Write-Host "(Y/N)" -ForegroundColor Yellow -NoNewline $(Write-Host "You want to Publish the App in Intune? " -ForegroundColor Green -NoNewLine))
        Write-Host ""
 
        if ($queryPublishApp -eq $true)
        {
            $PathSoftware = Join-Path $PSScriptRoot "Software"
            $MSIntune.SetRootPathSoftware($PathSoftware)
            if ($MSIntune.PublishSoftware($config.GetConfig('softName'), $config.GetConfig('softVerName'), $config.GetConfig("intunewinPathSoftware")) -eq $false)
            {
                pause
            }
        }
    }
    # --- END --- Seccion Publica App

} while ($true)
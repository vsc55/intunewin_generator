# Cambiar la codificación de caracteres de la consola a UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8


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
$config.NewConfig("softVerName", "") | Out-Null
$config.NewConfig("softVerPath", "") | Out-Null
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
Write-Host ""



if ($debug) {
    Write-Host ""
    Write-Host "*** DEBUG ***"
    $config.ShowConfig()
    Write-Host ""
    $paths.ShowPaths()
    Write-Host "*** DEBUG ***"
    Write-Host ""
    pause
}




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
    Write-Host "Puedes descargarlo manualmente de: $intuneWinAppUtilUrlGitHub" -ForegroundColor Blue
    Write-Host ""
    exit 1
}
Remove-Variable -Name "downloader" -Scope Global
$config.SetConfig('intuneWinAppUtilPath', $intuneWinAppUtilPath)
Write-Host ""




if ($debug) {
    Write-Host ""
    Write-Host "*** DEBUG ***"
    $config.ShowConfig()
    Write-Host "*** DEBUG ***"
    Write-Host ""
    pause
}




$softArgs = @{
    lNames   = (Get-ChildItem -Path $paths.GetPath('software') -Directory | Sort-Object Name)
    title    = "Lista de Software"
    msgEmpty = "No se ha detectado ningun Software."
    msgSelect = "Seleccione un Software"
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



if ($debug) {
    Write-Host ""
    Write-Host "*** DEBUG ***"
    $config.ShowConfig()
    Write-Host ""
    $paths.ShowPaths()
    Write-Host "*** DEBUG ***"
    Write-Host ""
    pause
}




$verArgs = @{
    lNames   = (Get-ChildItem -Path $config.GetConfig('softPathSrc') -Directory | Sort-Object Name -Descending)
    title    = ("Generar archivo intunewin para [{0}]" -f $config.GetConfig('softName'))
    msgEmpty = ("No se han detectado versiones para [{0}]" -f $config.GetConfig('softName'))
    msgSelect = "Seleccione una version"
    msgSelectErr = "Algo ha salido mal ya que no se ha seleccionado ningún Software :("
}
$tmpSelectedVersionSoftware = SelectItemList @verArgs
if ([string]::IsNullOrEmpty($tmpSelectedVersionSoftware))
{
    exit 1    
}
$config.SetConfig("softVerName", $tmpSelectedVersionSoftware)
$config.SetConfig("softVerPath", $paths.GetPathJoin('source', $tmpSelectedVersionSoftware))
Remove-Variable -Name "tmpSelectedVersionSoftware" -Scope Global

Write-Host ("Version seleccionado: {0} - {1}" -f $config.GetConfig('softName'), $config.GetConfig('softVerName')) -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1




if ($debug) {
    Write-Host ""
    Write-Host "*** DEBUG ***"
    $config.ShowConfig()
    Write-Host "*** DEBUG ***"
    Write-Host ""
    pause
}





$tmpAppCmdInstall = Get-ValidInstallCmd -softCmdInstall $config.GetConfig('softCmdInstall') -softVerPath $config.GetConfig('softVerPath') -validExtensions @(".exe", ".com", ".bat", ".cmd", ".ps1")
if ([string]::IsNullOrEmpty($tmpAppCmdInstall))
{
    exit 1
}
$config.SetConfig('softCmdInstall', $tmpAppCmdInstall)
Remove-Variable -Name "tmpAppCmdInstall" -Scope Global

Write-Host ("Script/Programa de Instalacion: {0}" -f $config.GetConfig('softCmdInstall')) -ForegroundColor Green
Write-Host ""
Start-Sleep -Seconds 1





Clear-Host
Write-Host ""
Write-Host " Resumen:" -ForegroundColor Yellow
Write-Host ("  - Software: {0}" -f $config.GetConfig('softName')) -ForegroundColor Blue
Write-Host ("  - Version : {0}" -f $config.GetConfig('softVerName')) -ForegroundColor Blue
Write-Host ""
Write-Host ("  - Source: {0}" -f $config.GetConfig('softVerPath')) -ForegroundColor Cyan
Write-Host ("  - Script: {0}" -f $config.GetConfig('softCmdInstall')) -ForegroundColor Cyan
Write-Host ""
Write-Host ("  - Salida: {0}" -f $config.GetConfig('softPathOut')) -ForegroundColor Green
Write-Host ""

if ($debug) {
    Write-Host ""
    Write-Host "*** DEBUG ***"
    $config.ShowConfig()
    Write-Host ""
    $paths.ShowPaths()
    Write-Host "*** DEBUG ***"
    Write-Host ""
}

pause




Write-Host ""
Clear-Host
$compileIntuneWin                 = [intuneWinAppUtil]::new($config.GetConfig('intuneWinAppUtilPath'))
$compileIntuneWin.outPath         = $config.GetConfig('softPathOut')
$compileIntuneWin.sourcePath      = $config.GetConfig('softVerPath')
$compileIntuneWin.cmdInstall      = $config.GetConfig('softCmdInstall')
$compileIntuneWin.softwareName    = $config.GetConfig('softName')
$compileIntuneWin.softwareVersion = $config.GetConfig('softVerName')

$config.SetConfig("intunewinName", $compileIntuneWin.GetNameFileIntuneWin())
$config.SetConfig("intunewinPath", $compileIntuneWin.GetPathFileIntuneWin())
$config.SetConfig("intunewinNameSoftware", $compileIntuneWin.GetNameFileIntuneWinSoftware())
$config.SetConfig("intunewinPathSoftware", $compileIntuneWin.GetPathFileIntuneWinSoftware())

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
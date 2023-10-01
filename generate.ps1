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




$modulesDep = @("MSGraph", "IntuneWin32App", "AzureAD", "PSIntuneAuth")
foreach ($module in $modulesDep) {
    
    Write-Host ("Comprobando modulo '{0}'..." -f $module) -ForegroundColor Yellow -NoNewline
    if (-not (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue))
    {
        Write-Host (" [No Instalado]") -ForegroundColor Red
        $installModuleQuery = QueryYesNo -msg ("¿Deseas instalar el módulo '{0}'? (Y/N)" -f $module)
        if ($installModuleQuery -eq $false)
        {
            Write-Host ("Abortamos: El modulo '{0}' es necesario!" -f $module) -ForegroundColor Red
            Write-Host ""
            Exit 1
        }
        Write-Host ("Instalando el modulo '{0}'..." -f $module) -ForegroundColor Yellow  -NoNewline
        try {
            Install-Module -Name $module -Scope CurrentUser -Force -ErrorAction Stop
        }
        catch
        {
            Write-Host (" [Error]") -ForegroundColor Red
            Write-Host ""
            # $errCode     = $_.Exception.HResult
            $errMsg      = $_.Exception.Message
            $errLocation = $_.InvocationInfo.PositionMessage
            Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red
            Write-Host ""
            Exit 1
        }
        Write-Host (" [OK]") -ForegroundColor Green
        Write-Host ""
    }
    else
    {
        Write-Host (" [OK]") -ForegroundColor Green
    }
}
Write-Host ""



#Pre-reqs = Install-Module MSGraph, IntuneWin32App, AzureAD, and PSIntuneAuth

#Connect to Graph API - Commented out if running from master file. if running individually, uncomment below line.
$TenantID = Read-Host "Enter your TenantID (i.e. - domain.com or domain.onmicrosoft.com)"
$TenantConnection = ConnectTenantMSIntune -TenantID $TenantID
if ($TenantConnection -eq $false)
{
    Exit 1
}


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



do {
    # Reseteamos ajuste a los valores por defecto excepto "intuneWinAppUtilPath".
    # También eliminamos los Paths del soft seleccionado.
    $resetExceptionConfig = @("intuneWinAppUtilPath")
    $config.ResetAllToDefault($resetExceptionConfig)
    $paths.DelPath("source") | Out-Null
    $paths.DelPath("out") | Out-Null
    $paths.DelPath("src") | Out-Null
    $paths.DelPath("cat") | Out-Null

   
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
    $config.SetConfig("softVerPathSrc", (Join-Path $config.GetConfig('softVerPath') "src"))
    $config.SetConfig("softVerPathCat", (Join-Path $config.GetConfig('softVerPath') "cat"))

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




    # --- INI --- Seccion Publica App

    $queryPublicApp = $false
    if ($TenantID -ne "")
    {
        $queryPublicApp = QueryYesNo -msg "¿Quieres Publicar la App? (Y/N)"
        Write-Host ""
    }

    if ($queryPublicApp -eq $true)
    {
        $abortPublicApp = $false
        $config.SetConfig("softPathInfo", (Join-Path $config.GetConfig('softVerPath') "info.json"))
        if (-not (Test-Path -Path $config.GetConfig('softPathInfo') -PathType Leaf))
        {
            $config.SetConfig("softPathInfo", (Join-Path $config.GetConfig('softPath') "info.json"))
            if (-not (Test-Path -Path $config.GetConfig('softPathInfo') -PathType Leaf))
            {
                Write-Host ("No se detecto info.json") -ForegroundColor Yellow
                Write-Host ""
                Start-Sleep -Seconds 1
                $abortPublicApp = $true
            }
        }

        # Read config json
        if ($abortPublicApp -eq $false)
        {
            $abortPublicApp    = $true
            $Win32AppArgs      = @{}
            $Win32AppRemplaces = @{}
            if (Test-Path $config.GetConfig('softPathInfo') -PathType Leaf)
            {
                try
                {
                    $infoJsonContent = Get-Content -Raw -Path $config.GetConfig('softPathInfo') | ConvertFrom-Json
                    if ($infoJsonContent.PSObject.Properties.Name -contains "Win32App")
                    {
                        $infoJsonContent.Win32App.PSObject.Properties | ForEach-Object {
                            $Win32AppArgs[$_.Name] = $_.Value
                        }
                    }
                    if ($infoJsonContent.PSObject.Properties.Name -contains "Remplaces")
                    {
                        $Win32AppRemplaces = $infoJsonContent.Remplaces
                    }
                    $abortPublicApp = $false
                }
                catch
                {
                    # $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red
                }
            }
            else
            {
                Write-Host ("File {0} not found. :(" -f $configFile) -ForegroundColor Red
            }
        }

        # Check file intunewin exist
        if ($abortPublicApp -eq $false)
        {
            $Win32AppArgs['FilePath'] = $config.GetConfig("intunewinPathSoftware")
            if (-not (Test-Path -Path $Win32AppArgs['FilePath'] -PathType Leaf))
            {
                Write-Host ("No se ha encontrado el archivo [{0}]" -f $Win32AppArgs['FilePath']) -ForegroundColor Yellow
                Write-Host ""
                Start-Sleep -Seconds 1
                $abortPublicApp = $true
            }
            else
            {
                # $IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $Win32AppArgs['FilePath']
            }
        }

        # Connect Tenant
        if ($abortPublicApp -eq $false)
        {
            $TenantConnection = ConnectTenantMSIntune -TenantID $TenantID
            if ($TenantConnection -eq $false)
            {
                $abortPublicApp = $false
            }
        }
        
        # Public App
        if ($abortPublicApp -eq $false)
        {
            # "AppVersion" = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
            $Win32AppArgs['AppVersion']  = $config.GetConfig('softVerName')
            # $Win32AppArgs['DisplayName'] = "{0} {1}" -f $Win32AppArgs['DisplayName'], $Win32AppArgs['AppVersion']

            
            $NewAppDipalyName = $Win32AppArgs['DisplayName']
            $NewAppVersion    = $Win32AppArgs['AppVersion']
            $Win32AppLatest   = Get-IntuneWin32App -DisplayName $NewAppDipalyName | Where-Object { $_.displayVersion -eq $NewAppVersion }

           
            if ($null -eq $Win32AppLatest)
            {
                # Set Logo Path
                $config.SetConfig("softPathLogo", (Join-Path $config.GetConfig('softVerPath') "logo"))
                $config.SetConfig("softFileLogo", (Join-Path $config.GetConfig('softPathLogo') "logo.png"))
                if (-not (Test-Path -Path $config.GetConfig('softFileLogo') -PathType Leaf))
                {
                    $config.SetConfig("softPathLogo", (Join-Path $config.GetConfig('softPath') "logo"))
                    $config.SetConfig("softFileLogo", (Join-Path $config.GetConfig('softPathLogo') "logo.png"))

                    if (-not (Test-Path -Path $config.GetConfig('softFileLogo') -PathType Leaf))
                    {
                        $config.SetConfig("softFileLogo", "")
                        Write-Host ("No se detecto logo") -ForegroundColor Yellow
                        Write-Host ""
                    }
                }
                if ($config.GetConfig('softFileLogo') -ne "" -and (Test-Path -Path $config.GetConfig('softFileLogo') -PathType Leaf))
                {
                    $Win32AppArgs['Icon'] = New-IntuneWin32AppIcon -FilePath $config.GetConfig('softFileLogo')
                }



                #Create Requirement Rule
                $Win32AppArgs['RequirementRule'] = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedWindowsRelease "W10_21H1"



                # detection rules
                $DetectionRuleScriptFile = "D:\Source\intunewin_generator\Software\test1\upload\SEH_UTN_Manager_Detection_Method_3.3.10.ps1"
                $Win32AppArgs['DetectionRule'] = New-IntuneWin32AppDetectionRuleScript -ScriptFile $DetectionRuleScriptFile -EnforceSignatureCheck $false -RunAs32Bit $false



                # Create custom return code
                # $ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1337 -Type retry
                # $Win32AppArgs['ReturnCode'] = $ReturnCode


                Write-Host ("Publicando App [{0} {1}]..." -f $Win32AppArgs['DisplayName'], $Win32AppArgs['AppVersion']) -ForegroundColor Green
                Add-IntuneWin32App @Win32AppArgs
                Write-Host ("Publicacion completa!" -f $OldAppVersion, $NewAppVersion) -ForegroundColor Green
                Write-Host ""
                Start-Sleep -Seconds 1


                # Update Old Version
                if ($Win32AppRemplaces.PSObject.Properties.Name -contains $Win32AppArgs['AppVersion'])
                {
                    $OldAppVersion = $Win32AppRemplaces.PSObject.Properties[$NewAppVersion].Value
                    
                    Write-Host ("Asignando sustitucion de version ({0}) por ({1})..." -f $OldAppVersion, $NewAppVersion) -ForegroundColor Green

                    $Win32AppLatest   = Get-IntuneWin32App -DisplayName $NewAppDipalyName | Where-Object { $_.displayVersion -eq $NewAppVersion }
                    $Win32AppPrevious = Get-IntuneWin32App -DisplayName $NewAppDipalyName | Where-Object { $_.displayVersion -eq $OldAppVersion }

                    $AllowSupersedence = $true
                    if ($Win32AppLatest -is [System.Object])
                    {
                        if ($Win32AppLatest.PSObject.Properties.Match('Count').Count -gt 0)
                        {
                            $AllowSupersedence = $false
                            Write-Host ("Se ha encontrado esta version de la app repetida {0} veces. Echa un ojo a ver que esta pasa!" -f $Win32AppLatest.Count) -ForegroundColor Red
                            Write-Host ""
                            Get-IntuneWin32App -DisplayName $NewAppDipalyName | Where-Object { $_.displayVersion -eq $NewAppVersion } | Select-Object -Property displayName, displayVersion, id, createdDateTime | Sort-Object -Property createdDateTime
                            Write-Host ""
                            pause
                        }
                    }
                    if ($AllowSupersedence -eq $true)
                    {
                        $Supersedence = New-IntuneWin32AppSupersedence -ID $Win32AppPrevious.id -SupersedenceType "Replace" # Replace for uninstall, Update for updating
                        Add-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Supersedence $Supersedence
                        # Get-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Verbose
                        # Remove-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Verbose

                        Write-Host ("Sustitucion completa!" -f $OldAppVersion, $NewAppVersion) -ForegroundColor Green
                        Write-Host ""
                        Start-Sleep -Seconds 1
                    }
                }
            }
            else
            {
                if ($Win32AppLatest -is [System.Object])
                {
                    if ($Win32AppLatest.PSObject.Properties.Match('Count').Count -gt 0)
                    {
                        Write-Host ("Se ha encontrado esta version de la app repetida {0} veces. Echa un ojo a ver que esta pasa!" -f $Win32AppLatest.Count) -ForegroundColor Red
                        Write-Host ""
                        Get-IntuneWin32App -DisplayName $NewAppDipalyName | Where-Object { $_.displayVersion -eq $NewAppVersion } | Select-Object -Property displayName, displayVersion, id, createdDateTime | Sort-Object -Property createdDateTime
                    }
                    elseif ($Win32AppLatest.PSObject.Properties.Match('id').Count -gt 0)
                    {
                        Write-Host ("Actualizando PackageFile de la App [{0} {1}]..." -f $Win32AppArgs['DisplayName'], $Win32AppArgs['AppVersion']) -ForegroundColor Green
                        Update-IntuneWin32AppPackageFile -ID $Win32AppLatest.id -FilePath $Win32AppArgs['FilePath']
                        Write-Host ("Actualizcion completa!" -f $OldAppVersion, $NewAppVersion) -ForegroundColor Green
                    }
                    else
                    {
                        Write-Host ("Actualizando PackageFile abortada, no se detecto ID!") -ForegroundColor Red
                    }
                    Write-Host ""
                    Start-Sleep -Seconds 1
                }
                else
                {
                    $formatoResult = ""
                    if ($null -eq $Win32AppLatest)
                    {
                        $formatoResult = "Null"
                    }
                    elseif ($Win32AppLatest -is [int])
                    {
                        $formatoResult = "Int"
                    }
                    elseif ($Win32AppLatest -is [string])
                    {
                        $formatoResult = "String"
                    }
                    elseif ($Win32AppLatest -is [bool])
                    {
                        $formatoResult = "Bool"
                    }
                    elseif ($Win32AppLatest -is [double])
                    {
                        $formatoResult = "Double"
                    }
                    elseif ($Win32AppLatest -is [array])
                    {
                        $formatoResult = "Array"
                    }
                    elseif ($Win32AppLatest -is [Hashtable])
                    {
                        $formatoResult = "Hashtable"
                    }
                    elseif ($Win32AppLatest -is [DateTime])
                    {
                        $formatoResult = "DateTime"
                    }
                    else
                    {
                        $formatoResult = "Unknown"
                    }

                    Write-Host ("Formato no valido [{0}] en la deteccion de si existe el pakete en Intune!" -f $formatoResult) -ForegroundColor Red
                    Write-Host ""
                    Start-Sleep -Seconds 1
                    pause
                }
            }
        }
    }

    # --- END --- Seccion Publica App

} while ($true)
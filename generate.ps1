# **** INIT - Load libs ****
$isLoad    = $true;
$hackCheck = "1984"
$debug     = $false

$PSScripotName    = "IntuneWin Gnerator"
$PSScripotVersion = "1.0"

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

Write-Host ""
Write-Host ("{0} {1} by Javier Pastor (VSC55)" -f $PSScripotName, $PSScripotVersion) -ForegroundColor Green
Write-Host ("Run in PowerShell {0} in {1}" -f $PSVersionTable.PSVersion.ToString(), $PSVersionTable.OS) -ForegroundColor Green
Write-Host ""

$rootPath    = $PSScriptRoot;
$initLibPath = Join-Path $rootPath "lib"
if (-not (Test-Path -Path $initLibPath -PathType Container))
{
    Write-Host "Error: No Lib Found!" -ForegroundColor Red
    Exit 1
}

Set-Location -Path $initLibPath
Import-Module .\global.ps1

Set-Location -Path $rootPath
if (-not $isLoad)
{
    Write-Host "Error Loading Libs!" -ForegroundColor Red
    Exit 1
}
# **** END - Load libs ****


# **** INIT - Crear Objetos Globales ****
$paths = [PathItemPool]::new()
$paths.root = $rootPath

$paths.AddPath("lib", $null, $true) | Out-Null
$paths.AddPath("bin", $null, $true) | Out-Null
$paths.AddPath("software", $null, $true) | Out-Null


$config     = [Config]::new(@{})
$configFile = Join-Path $rootPath "config.json"

$config.NewConfig("TenantID", "") | Out-Null
$config.NewConfig("SetupFileDefault", "install.cmd") | Out-Null
$config.NewConfig("IntuneWinAppUtilExe", "IntuneWinAppUtil.exe") | Out-Null
$config.NewConfig("intuneWinAppUtilUrlDownload", "https://raw.githubusercontent.com/microsoft/Microsoft-Win32-Content-Prep-Tool/master/IntuneWinAppUtil.exe") | Out-Null
$config.NewConfig("intuneWinAppUtilUrlGitHub", "https://github.com/microsoft/Microsoft-Win32-Content-Prep-Tool") | Out-Null
$config.NewConfig('intuneWinAppUtilPath', $paths.GetPathJoin('bin', $config.GetConfig("IntuneWinAppUtilExe")))  | Out-Null

if (Test-Path $configFile -PathType Leaf)
{
    if ($config.LoadConfig($configFile))
    {
        Write-Host "Configuration Loaded Successfully." -ForegroundColor Green
    }
    else
    {
        Write-Host "Error Loading Configuration!!" -ForegroundColor Red
        Exit 1
    }
}
else
{
    Write-Warning "The Configuration File Does Not Exist!!"
}
Start-Sleep -Seconds 2
Write-Host ""

ShowDebugObj
# **** END - Crear Objetos Globales ****


# **** INIT - Crear objeto MSIntune ****
$MSIntune = [intuneWin32AppCustom]::new("")
$MSIntune.SetRootPathSoftware($paths.GetPath('software'))

if ($MSIntune.CheckModulesDeps($true, $false) -eq $false)
{
    Write-Warning "Dependencies Are Missing, Intune Support Is Disabled!!"
    $MSIntune.SetEnabled($false)
    pause
}
else
{
    $TenantID = $config.GetConfig("TenantID")
    if (-not [string]::IsNullOrEmpty($TenantID))
    {
        $queryAutConnectTenant = QueryYesNo -Msg ("Do you want to connect to Tenant '{0}'?" -f $TenantID) -ForegroundColor Green
        if (-not $queryAutConnectTenant)
        {
            $TenantID = ""
        }
    }
    if ([string]::IsNullOrEmpty($TenantID))
    {
        $TenantID = $(Write-Host "Enter Your TenantID (i.e. - domain.com or domain.onmicrosoft.com): " -ForegroundColor Green -NoNewLine; Read-Host)
    }

    $MSIntune.SetTenantID($TenantID)
    $MSIntune.ConnectMSIntune($true) | Out-Null
}
Write-Host ""
Start-Sleep -Seconds 2
# **** END - Crear objeto MSIntune ****


# **** INIT - Descargar IntuneWinAppUtil ****
$downloader = [FileDownloader]::new()
$downloader.DownloadFile($config.GetConfig("intuneWinAppUtilUrlDownload"), $config.GetConfig('intuneWinAppUtilPath'), $config.GetConfig("IntuneWinAppUtilExe"), $false) | Out-Null
$downloader.showMsg   = $true
$downloader.overWrite = $false
$downloadResult = $downloader.StartDownload()
if (-not $downloadResult)
{
    Write-Warning ("You Can Download It Manually From: {0}" -f $config.GetConfig("intuneWinAppUtilUrlGitHub"))
}
Remove-Variable -Name "downloader" -Scope Global
Write-Host ""
Start-Sleep -Seconds 2
# **** END - Descargar IntuneWinAppUtil ****

do {
    # Reseteamos ajuste a los valores por defecto excepto "intuneWinAppUtilPath".
    # También eliminamos los Paths del soft seleccionado.
    $config.ResetAllToDefault(@("intuneWinAppUtilPath"))

    $PathSoftwareAll = $paths.GetPath('software')

    $softArgs = @{
        lNames       = (Get-ChildItem -Path $PathSoftwareAll -Directory | Sort-Object Name | Select-Object -ExpandProperty Name)
        title        = "Software List"
        msgEmpty     = "No Software Detected!"
        msgSelect    = "Select a Software"
        msgSelectErr = "Something Has Gone Wrong Since No Software Has Been Selected :("
    }
    $softName = SelectItemList @softArgs
    if ([string]::IsNullOrEmpty($softName))
    {
        exit 1
    }
    $PathSoftwareSrc = Join-Path $paths.GetPathJoin('software',  $softName) "source"
    $PathSoftwareOut = Join-Path $paths.GetPathJoin('software',  $softName) "out"

    Write-Host ""
    Write-Host ("- Selected Software: {0}" -f $softName) -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 1


    ShowDebugObj


    $verArgs = @{
        lNames       = (Get-ChildItem -Path $PathSoftwareSrc -Directory | Sort-Object Name -Descending | Select-Object -ExpandProperty Name)
        title        = ("List Of '{0}' Software Versions" -f $softName)
        msgEmpty     = ("No Version Detected For '{0}' Software" -f $softName)
        msgSelect    = "Select a Version"
        msgSelectErr = "Something Has Gone Wrong Since No Software Version Has Been Selected :("
    }
    $softVersion = SelectItemList @verArgs
    if ([string]::IsNullOrEmpty($softVersion))
    {
        continue
        # exit 1
    }
    $PathSoftwareVersions = Join-Path $PathSoftwareSrc $softVersion
    $PathSoftwareVersionsSrc = Join-Path $PathSoftwareVersions "src"

    Write-Host ""
    Write-Host ("Selected Version: {0} - {1}" -f $softName, $softVersion) -ForegroundColor Green
    Write-Host ""
    Start-Sleep -Seconds 1


    ShowDebugObj



    $SetupFile  = $config.GetConfig("SetupFileDefault")
    $softSource = $PathSoftwareVersionsSrc
    $softOut    = $PathSoftwareOut



    $IntuneWinFileNameSoftware    = $MSIntune.GetFileIntuneWinSoftware($softName, $softVersion)
    $IntuneWinPathOutFileSoftware = $MSIntune.GetPathOutFileIntuneWinSoftware($softName, $softVersion)
    $IntuneWinPathOutFileSetup    = $MSIntune.GetPahtOutFileIntuneWinSetupFile($softName, $SetupFile)

    $IntuneWinBuildOk = $false




    # TODO: Pendiente añadir aqui la edicion de info.json




    # --- INIT --- Resumen de lo que se ha seleccionado
    Clear-Host
    Write-Host                                                                               ("╔═══════════════════════════════════════╗") -ForegroundColor Green
    Write-Host                                                                               ("║             ┌───────────┐             ║") -ForegroundColor Green
    Write-Host                                                                               ("╟─────────────┤  Summary  ├─────────────╢") -ForegroundColor Green
    Write-Host                                                                               ("║             └───────────┘             ║") -ForegroundColor Green
    Write-Host                                                                               ("╚══╦════════════════════════════════════╝") -ForegroundColor Green 
    Write-Host                                                                               ("   ║") -ForegroundColor Green
    Write-Host ("{0} v{1}" -f $softName, $softVersion) -ForegroundColor Yellow  $(Write-Host ("   ╚══╤══════█ ") -ForegroundColor Green -NoNewline )
    Write-Host                                                                               ("      │") -ForegroundColor Green
    Write-Host $softSource -ForegroundColor Cyan                                $(Write-Host ("      ├──┬───► Source    : ") -ForegroundColor Green -NoNewline )
    Write-Host $SetupFile -ForegroundColor Cyan                                 $(Write-Host ("      │  └───► Install   : ") -ForegroundColor Green -NoNewline )
    Write-Host                                                                               ("      │") -ForegroundColor Green
    Write-Host $SoftOut -ForegroundColor Cyan                                   $(Write-Host ("      └──┬───► Out       : ") -ForegroundColor Green -NoNewline )
    Write-Host $IntuneWinFileNameSoftware -ForegroundColor Cyan                 $(Write-Host ("         └───► IntuneWin : ") -ForegroundColor Green -NoNewline )
    Write-Host ""
    $(Write-Host "Press enter to continue..." -ForegroundColor Green -NoNewLine); Read-Host | Out-Null
    Write-Host ""
    # --- END --- Resumen de lo que se ha seleccionado




    # --- INIT --- Section Build Intunewin
    if ([string]::IsNullOrEmpty($IntuneWinPathOutFileSoftware) -or [string]::IsNullOrEmpty($IntuneWinPathOutFileSetup))
    {
        Write-Host ("IntuneWin Out Files is Not Defined!") -ForegroundColor Red
    }
    else
    {
        $queryRebuildApp = $true
        if (Test-Path -Path $IntuneWinPathOutFileSoftware -PathType Leaf)
        {
            $queryRebuildApp = QueryYesNo -Msg ("The IntuneWin File '{0}' Exists, Do You Want To ReBuild?" -f $IntuneWinFileNameSoftware) -ForegroundColor Green
            Write-Host ""
        }
        if ($queryRebuildApp)
        {
            $Win32AppPackage = $MSIntune.CreateIntuneWin32AppPackage($softSource, $SetupFile, $softOut, $true, $config.GetConfig('intuneWinAppUtilPath'))
            if ($Win32AppPackage.Status)
            {
                if ($MSIntune.RenameIntuneWinSetupFile($softName, $softVersion, $SetupFile, $true))
                {
                    $IntuneWinBuildOk = $true
                }
                Write-Host ""
            }
            if (-not $IntuneWinBuildOk)
            {
                Write-Host "Abort!" -ForegroundColor Red
                Write-Host ""
                pause
            }
        }
        else
        {
            if (Test-Path -Path $IntuneWinPathOutFileSoftware -PathType Leaf)
            {
                $IntuneWinBuildOk = $true
            }
        }

        if (Test-Path -Path $IntuneWinPathOutFileSetup -PathType Leaf)
        {
            Write-Host "Cleaning..." -ForegroundColor Green -NoNewLine
            try
            {
                Remove-Item -Path $IntuneWinPathOutFileSetup -Force
                Write-Host (" [√]") -ForegroundColor Green
            }
            catch
            {
                Write-Host (" [X]") -ForegroundColor Red
                Write-Host ("Error Cleaning: {0}" -f $_) -ForegroundColor Red
                Write-Host ""
            }            
        }
    }
    # --- END --- Section Build Intunewin




    # --- INIT --- Seccion Publish App
    if ($IntuneWinBuildOk -and $MSIntune.GetIsEnabled())
    {
        $queryPublishApp = $false
        $queryPublishApp = QueryYesNo -Msg "You want to Publish the App in Intune?" -ForegroundColor Green
        Write-Host ""
 
        if ($queryPublishApp -eq $true)
        {
            if ($MSIntune.PublishSoftware($softName, $softVersion, $IntuneWinPathOutFileSoftware) -eq $false)
            {
                pause
            }
        }
    }
    # --- END --- Seccion Publica App

} while ($true)
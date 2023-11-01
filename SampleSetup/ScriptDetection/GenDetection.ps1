# Version 1.1

# Changelog:
# ----------
#   Ver 1.0:
#       - Init Version (Javier Pastor)
#
#   Ver 1.1:
#       - Allow selecting FileVersion or ProductVersion for the way to get the file version. (Javier Pastor)
#

$AppName       = "App1"               # Nombre de la App, se usará en el inicio del nombre del archivo del script de detección.
$AppPathFull   = "C:\App1\App1.exe"   # Ruta completa del archivo del que se va a obtener la información de la versión para la detección.
$AppModeGetVer = "FileVersion"        # Modo en el que se obtiene la versión de la App, puede ser FileVersion o ProductVersion

function CreateDetectionFileApp {
    param (
        [string]$AppName,
        [string]$AppPathFull,
        [string]$DetectionType  = "FileExist",      # Valid options [FileExist|Version]
        [string]$FileVersion    = "",               # Version App, e.g.: 1.0.0.5
        [string]$PropVersion    = "FileVersion"     # Valid options [FileVersion|ProductVersion]
    )

    $AppName        = $AppName.Trim()
    $AppPathFull    = $AppPathFull.Trim()
    $DetectionType  = $DetectionType.Trim()
    $PropVersion    = $PropVersion.Trim()

    # Check de si PropVersion es válido, si no es válido usamos FileVersion como valor default.
    if (@('FileVersion', 'ProductVersion') -contains $PropVersion -eq $False) {
        $PropVersion = 'FileVersion'
    }

    $ComentApp = $AppName
    $FileName  = "{0}_Detection_Method_{1}" -f $AppName, $DetectionType
    $ifDetect  = '(Test-Path -Path "{0}" -PathType Leaf)' -f $AppPathFull
    
    if (![string]::IsNullOrEmpty($FileVersion))
    {
        $ComentApp += " {0}" -f $FileVersion
        $FileName  += "_{0}" -f $FileVersion
        $ifDetect  += ' -and ([String](Get-Item -Path "{0}").VersionInfo.{1} -eq "{2}")' -f $AppPathFull, $PropVersion, $FileVersion
    }
    $FileName += ".ps1"

    $FilePath      = Join-Path -Path $PSScriptRoot -ChildPath $FileName
    $scriptContent = @"
# Detection mode $DetectionType, App $ComentApp
if ($ifDetect)
{
    Write-Host "Installed"
    Exit 0
}
else
{
    Exit 1
}
"@
    New-Item -Path "$FilePath" -Force
    $scriptContent | Out-File -FilePath "$FilePath" -Encoding utf8
}

if (Test-Path -Path $AppPathFull -PathType Leaf)
{
    if (@('FileVersion', 'ProductVersion') -contains $AppModeGetVer -eq $False) {
        $AppModeGetVer = 'FileVersion'
    }

    $FileVersion = (Get-Item -Path "$($AppPathFull)" -ErrorAction SilentlyContinue).VersionInfo.$AppModeGetVer
    CreateDetectionFileApp -AppName $AppName -AppPathFull $AppPathFull -DetectionType "Version" -FileVersion $FileVersion -PropVersion $AppModeGetVer
}
else
{
    Write-Host ("The file [{0}] does not exist, skipping Detection Version!" -f $AppPathFull)
}

CreateDetectionFileApp -AppName $AppName -AppPathFull $AppPathFull
Exit 0
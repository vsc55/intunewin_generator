
$AppIDMsi = "{ID_de_Tu_Aplicacion_MSI}"

$installerDirectory = Join-Path -Path $env:SystemRoot -ChildPath "Installer"
$pathMSIInstaller = Join-Path -Path $installerDirectory -ChildPath $AppIDMsi

if (Test-Path -Path $pathMSIInstaller -PathType Container)
{
    Write-Host ("Installed '{0}'" -f $AppIDMsi)
    Exit 0
}
else
{
    Exit 1
}
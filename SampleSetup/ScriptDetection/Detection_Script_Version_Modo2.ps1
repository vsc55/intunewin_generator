$AppVer  = "10.0.19041.3570"
$AppPath = "$Env:ProgramFiles\OpenShot Video Editor\openshot-qt.exe"

If([String](Get-Item -Path $AppPath -ErrorAction SilentlyContinue).VersionInfo.FileVersion -eq $AppVer)
{
    Write-Host ("Installed '{0}' v{1}" -f $AppPath, $AppVer)
    Exit 0
}
else
{
    Exit 1
}
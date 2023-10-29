
$AppPath = "$Env:ProgramFiles\OpenShot Video Editor"

if (Test-Path -Path $AppPath -PathType Container)
{
    Write-Host ("Installed '{0}'" -f $AppPath)
    Exit 0
}
else
{
    Exit 1
}
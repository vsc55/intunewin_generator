$AppVer  = "10.0.19041.3570"
$AppPath = "C:\Windows\System32\telnet.exe"

if ((Test-Path -Path $AppPath -PathType Leaf) -and [String](Get-Item -Path $AppPath).VersionInfo.ProductVersion -eq $AppVer)
{
    Write-Host ("Installed '{0}' v{1}" -f $AppPath, $AppVer)
    Exit 0
}
else
{
    Exit 1
}
$AppPath = "C:\Windows\System32\telnet.exe"

if (Test-Path -Path $AppPath -PathType Leaf)
{
    Write-Host ("Installed '{0}'" -f $AppPath)
    Exit 0
}
else
{
    Exit 1
}
$fileInf = "C:\Windows\System32\DriverStore\FileRepository\oemsetup.inf_amd64_9ff4daa03a3bf154\oemsetup.inf"

If(Test-Path -Path $fileInf -PathType Leaf)
{
    Write-Host "Installed"
    Exit 0
}
else
{
    Exit 1
}
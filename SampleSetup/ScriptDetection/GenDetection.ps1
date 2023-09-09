## Check for XXXXXXX (File Detection Method)

$AppName     = "GoogleEartPro"
$AppPathFull = "C:\Program Files\Google\Google Earth Pro\client\googleearth.exe"

$App         = (Get-ChildItem -Path $AppPathFull -ErrorAction SilentlyContinue)
$AppPath     = $($App.FullName).Replace("C:\Program Files\","")
$FileVersion = (Get-Item -Path "$($App.FullName)" -ErrorAction SilentlyContinue).VersionInfo.FileVersion


## Create Text File with File Detection Method Version
If(Test-Path -Path $AppPathFull -PathType Leaf)
{
    $FilePath = ".\{0}_Detection_Method_{1}.ps1" -f $AppName, $FileVersion
    New-Item -Path "$FilePath" -Force
    Set-Content -Path "$FilePath" -Value "If([String](Get-Item -Path `"`$Env:ProgramFiles\$AppPath`" -ErrorAction SilentlyContinue).VersionInfo.FileVersion -ge `"$FileVersion`"){"
    Add-Content -Path "$FilePath" -Value "Write-Host `"Installed`""
    Add-Content -Path "$FilePath" -Value "Exit 0"
    Add-Content -Path "$FilePath" -Value "}"
    Add-Content -Path "$FilePath" -Value "else {"
    Add-Content -Path "$FilePath" -Value "Exit 1"
    Add-Content -Path "$FilePath" -Value "}"
}
else {
    Write-Host ("No existe {0}, se omite Detection Version!" -f $AppPathFull)
}

## Create Text File with File Detection Method FileExist
$FilePath = ".\{0}_Detection_Method_FileExist.ps1" -f $AppName
New-Item -Path "$FilePath" -Force
Set-Content -Path "$FilePath" -Value "If(Test-Path -Path `"`$Env:ProgramFiles\$AppPath`"-PathType Leaf){"
Add-Content -Path "$FilePath" -Value "Write-Host `"Installed`""
Add-Content -Path "$FilePath" -Value "Exit 0"
Add-Content -Path "$FilePath" -Value "}"
Add-Content -Path "$FilePath" -Value "else {"
Add-Content -Path "$FilePath" -Value "Exit 1"
Add-Content -Path "$FilePath" -Value "}"
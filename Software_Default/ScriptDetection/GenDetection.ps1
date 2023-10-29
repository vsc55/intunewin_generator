## Check for XXXXXXX (File Detection Method)

$AppName     = "GoogleEartPro"
$AppPathFull = "C:\Program Files\Google\Google Earth Pro\client\googleearth.exe"

function CreateDetectionFileApp {
    param (
        [string]$AppName,
        [string]$AppPathFull,
        [string]$DetectionType = "FileExist",
        [string]$FileVersion   = ""
    )

    $ifDetect = '(Test-Path -Path "{0}" -PathType Leaf)' -f $AppPathFull
    if (![string]::IsNullOrEmpty($FileVersion))
    {
        $ifDetect += ' -and [String](Get-Item -Path "{0}").VersionInfo.FileVersion -eq "{1}"' -f $AppPathFull, $FileVersion
    }

    $FileName      = "{0}_Detection_Method_{1}.ps1" -f $AppName, $DetectionType
    $FilePath      = Join-Path -Path $PSScriptRoot -ChildPath $FileName
    $scriptContent = @"
if ($ifDetect) {
    Write-Host "Installed"
    Exit 0
} else {
    Exit 1
}
"@
    New-Item -Path "$FilePath" -Force
    $scriptContent | Out-File -FilePath "$FilePath" -Encoding utf8
}

if (Test-Path -Path $AppPathFull -PathType Leaf)
{
    $FileVersion = (Get-Item -Path "$($AppPathFull)" -ErrorAction SilentlyContinue).VersionInfo.FileVersion
    CreateDetectionFileApp -AppName $AppName -AppPathFull $AppPathFull -DetectionType "Version" -FileVersion $FileVersion
}
else
{
    Write-Host ("The file [{0}] does not exist, skipping Detection Version!" -f $AppPathFull)
}

CreateDetectionFileApp -AppName $AppName -AppPathFull $AppPathFull
Exit 0
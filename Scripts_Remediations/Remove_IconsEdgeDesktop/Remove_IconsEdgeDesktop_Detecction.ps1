$paths = @(
    "C:\Users\Public\Desktop\Microsoft Edge.lnk"
)

foreach ($path in $paths) {
    if (Test-Path $path -PathType Container)
    {
        # Es un directorio y existe
        Write-Host ("Dir {0} exist" -f $path)
        Exit 1
    }
    elseif (Test-Path $path -PathType Leaf)
    {
        # Es un archivo y existe
        Write-Host ("File {0} exist" -f $path)
        Exit 1
    }
}

Write-Host "No detect files"
Exit 0
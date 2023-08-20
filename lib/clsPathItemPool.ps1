if (-not (Test-Path Function:\CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    return
}

Import-Module .\clsPathItem.ps1

class PathItemPool {

    [string] $root = ""
    [PathItem[]] $pathItems = @()


    [bool] AddPath([string] $nameDir, [string] $rootpath = $null, [bool] $showmsg = $true) {
        # Agrega un nuevo directorio a la lista de rutas.
        # Retorna 'true' si el directorio se agregó exitosamente a la lista, 'false' si ya existe en la lista.

        if ([string]::IsNullOrWhiteSpace($nameDir))
        {
            if ($showmsg) { Write-Host "El valor de 'nameDir' no puede ser nulo ni vacio." -ForegroundColor Red }
            return $false
        }

        if ($this.isPathExists($nameDir))
        {
            if ($showmsg) { Write-Host "El directorio '$nameDir' ya existe en la lista." -ForegroundColor Yellow }
            return $false
        }
        if (-not $rootpath)
        {
            $rootpath = $this.root
        }

        $pathItem = [PathItem]::new($nameDir, $rootpath, $showmsg, $true)
        $this.pathItems += $pathItem
        return $true
    }

    [string] GetPath([string] $nameDir) {
        # Obtiene la ruta completa de un directorio en la lista de rutas.
        # Retorna la ruta completa del directorio si se encuentra en la lista, o 'null' si no se encuentra.

        $pathItem = $this.GetPathItem($nameDir)
        if ($null -ne $pathItem )
        {
            return $pathItem.GetPath()
        }
        return $null
    }

    [string] GetPathJoin([string] $nameDir, [string] $joinStr) {

        $base = $this.getPath($nameDir)
        if ($null -ne $base)
        {
            return Join-Path $base $joinStr
        }
        return $null
    }

    [PathItem] GetPathItem([string] $nameDir) {
        # Obtiene un objeto PathItem correspondiente al directorio especificado.
        # Retorna el objeto PathItem del directorio si se encuentra en la lista, o 'null' si no se encuentra.

        return $this.pathItems | Where-Object { $_.name -eq $nameDir }
    }

    [bool] isPathExists([string] $nameDir) {
        # Verifica si existe un directorio con el nombre especificado en la lista de rutas.
        # Retorna 'true' si existe un directorio con el nombre especificado en la lista, 'false' en caso contrario.

        return $this.GetPathItem($nameDir) | Measure-Object | Select-Object -ExpandProperty Count
    }

    [bool] PathExists([string] $nameDir) {
        # Muestra la lista de rutas en la consola.

        $pathItem = $this.GetPathItem($nameDir)
        if ($null -ne $pathItem)
        {
            return $pathItem.isPathExists()
        }
        return $false
    }

    [bool] DelPath([string] $nameDir) {
        # Elimina un directorio de la lista de rutas.
        # Retorna 'true' si el directorio se eliminó exitosamente de la lista, 'false' si no se encontró.

        $pathItem = $this.GetPathItem($nameDir)
        if ($null -ne $pathItem) {
            $this.pathItems.Remove($pathItem)
            return $true
        }
        return $false
    }

    [bool] UpdatePath([string] $nameDir, [string] $rootpath, [bool] $showmsg) {
        if ($this.isPathExists($nameDir))
        {
            $this.DelPath($nameDir)
        }
        return $this.AddPath($nameDir, $rootpath, $showmsg)
    }

    [void] ShowPaths() {
        Write-Host "Lista de rutas:"
        foreach ($pathItem in $this.pathItems) {
            Write-Host "$($pathItem.name) : $($pathItem.GetPath())"
        }
    }
}
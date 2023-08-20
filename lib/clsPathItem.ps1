if (($null -eq $function:CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    Exit 1
}

class PathItem {
    [string]$name   # Nombre del directorio
    [string]$path   # Ruta completa del directorio
    [bool]$showmsg  # Indica si se mostrarán mensajes


    PathItem([string] $name, [string] $rootpath, [bool] $showmsg, [bool] $create) {
        # Constructor de la clase PathItem que inicializa los valores.

        $this.name    = $name
        $this.showmsg = $showmsg

        $this.SetPath((Join-Path $rootpath $name))

        if ($create)
        {
            $this.CreateDirectoryIfNotExists()
        }
    }

    [bool] CreateDirectoryIfNotExists() {
        # Comprueba si el directorio no existe y lo crea si es necesario.
        # Retorna un valor booleano que indica si se ha creado el directorio.

        if (-not $this.isPathExists())
        {
            New-Item -Path $this.GetPath() -ItemType Directory
            if ($this.showmsg)
            {
                $this.WriteMessage("Creado directorio $($this.name)", "Green")
            }
        }
        return $true
    }

    [bool] isPathExists() {
        # Comprueba si el directorio existe.
        # Retorna un valor booleano que indica si el directorio existe.

        return Test-Path -Path $this.GetPath() -PathType Container
    }

    [void] WriteMessage([string] $message, [string] $color = $null) {
        # Escribe un mensaje en la consola con un color.

        if ($this.showmsg)
        {
            if ($color) { Write-Host $message -ForegroundColor $color }
            else        { Write-Host $message }
        }
    }

    [string] GetPath() {
        # Obtiene la ruta completa del directorio.
        return $this.path
    }

    [void] SetPath([string] $newPath) {
        # Establece una nueva ruta para el directorio.

        $this.path = $newPath
    }
}
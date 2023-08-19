
<#
.SYNOPSIS
Clase que representa un elemento de la lista de rutas.

.DESCRIPTION
La clase PathItem almacena información sobre un directorio, incluyendo su nombre, ruta completa y opciones de mensajes.

.PARAMETER name
El nombre del directorio.

.PARAMETER path
La ruta completa del directorio.

.PARAMETER showmsg
Indica si se deben mostrar mensajes en la consola.

#>
class PathItem {
    [string]$name   # Nombre del directorio
    [string]$path   # Ruta completa del directorio
    [bool]$showmsg  # Indica si se mostrarán mensajes


    <#
    .SYNOPSIS
    Constructor de la clase PathItem que inicializa los valores.

    .DESCRIPTION
    Este constructor inicializa los atributos del objeto PathItem con los valores proporcionados.

    .PARAMETER name
    El nombre del directorio.

    .PARAMETER rootpath
    La ruta raíz del directorio.

    .PARAMETER showmsg
    Indica si se mostrarán mensajes en la consola.

    .PARAMETER create
    Indica si se debe crear el directorio si no existe.

    .EXAMPLE
    $item = [PathItem]::new("myDir", "C:\Root", $true, $false)
    #>
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


    <#
    .SYNOPSIS
    Comprueba si el directorio no existe y lo crea si es necesario.

    .DESCRIPTION
    Este método verifica si el directorio especificado no existe y lo crea utilizando la ruta y nombre
    proporcionados en el constructor.

    .RETURNVALUE
    Retorna un valor booleano que indica si el directorio se ha creado exitosamente.

    .EXAMPLE
    $item = [PathItem]::new("myDir", "C:\Root", $true, $false)
    $item.CreateDirectoryIfNotExists()
    #>
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


    <#
    .SYNOPSIS
    Comprueba si el directorio existe.

    .DESCRIPTION
    Este método verifica si el directorio asociado al objeto PathItem existe en el sistema de archivos.

    .RETURNVALUE
    Retorna un valor booleano que indica si el directorio existe.

    .EXAMPLE
    $item = [PathItem]::new("myDir", "C:\Root", $true, $false)
    $item.isPathExists()
    #>
    [bool] isPathExists() {
        # Comprueba si el directorio existe.
        # Retorna un valor booleano que indica si el directorio existe.

        return Test-Path -Path $this.GetPath() -PathType Container
    }


    <#
    .SYNOPSIS
    Escribe un mensaje en la consola con un color opcional.

    .DESCRIPTION
    Este método muestra un mensaje en la consola, con la opción de especificar un color para el mensaje.

    .PARAMETER message
    El mensaje que se mostrará en la consola.

    .PARAMETER color
    El color del mensaje. Si no se especifica, se usará el color predeterminado.

    .EXAMPLE
    $item = [PathItem]::new("myDir", "C:\Root", $true, $false)
    $item.WriteMessage("Directorio creado.", "Green")
    #>
    [void] WriteMessage([string] $message, [string] $color = $null) {
        # Escribe un mensaje en la consola con un color.

        if ($this.showmsg)
        {
            if ($color) { Write-Host $message -ForegroundColor $color }
            else        { Write-Host $message }
        }
    }


    <#
    .SYNOPSIS
    Obtiene la ruta completa del directorio.

    .DESCRIPTION
    Este método devuelve la ruta completa del directorio asociado al objeto PathItem.

    .RETURNVALUE
    La ruta completa del directorio.

    .EXAMPLE
    $item = [PathItem]::new("myDir", "C:\Root", $true, $false)
    $item.GetPath()
    #>
    [string] GetPath() {
        # Obtiene la ruta completa del directorio.
        return $this.path
    }


    <#
    .SYNOPSIS
    Establece una nueva ruta para el directorio.

    .DESCRIPTION
    Este método permite cambiar la ruta del directorio asociado al objeto PathItem.

    .PARAMETER newPath
    La nueva ruta para el directorio.

    .EXAMPLE
    $item = [PathItem]::new("myDir", "C:\Root", $true, $false)
    $item.SetPath("D:\NewPath")
    #>
    [void] SetPath([string] $newPath) {
        # Establece una nueva ruta para el directorio.

        $this.path = $newPath
    }
}



<#
.SYNOPSIS
Clase que representa una lista de elementos de directorio.

.DESCRIPTION
Esta clase proporciona una estructura para administrar y realizar operaciones en una lista de elementos de directorio.

.NOTES
Archivo: PathList.ps1
Autor: [Tu nombre]
Fecha de creación: [Fecha de creación]
Última modificación: [Fecha de última modificación]

.EXAMPLE
$rootPath = "C:\DirectorioRaiz"
$pathList = [PathList]::new($rootPath)
$pathList.AddPath("bin")
$pathList.AddPath("lib", $rootPath, $true)
$pathList.AddPath("data", $rootPath, $false)
$pathList.ShowPaths()
#>
class PathList {

    [string] $root = ""
    [PathItem[]] $pathItems = @()

    # PathList([string] $root) {
    #     $this.root = $root
    #     $this.paths = @{}
    # }


    <#
    .SYNOPSIS
    Agrega un nuevo directorio a la lista de rutas.

    .DESCRIPTION
    Este método agrega un nuevo directorio a la lista de rutas, permitiendo especificar la ruta raíz,
    nombre del directorio y si se deben mostrar mensajes en la consola.

    .PARAMETER nameDir
    El nombre del directorio que se desea agregar.

    .PARAMETER rootpath
    La ruta raíz para construir la ruta completa del directorio. Si no se proporciona, se usará el valor de 'root'.

    .PARAMETER showmsg
    Indica si se mostrarán mensajes en la consola.

    .RETURN
    Retorna 'true' si el directorio se agregó exitosamente a la lista, 'false' si ya existe en la lista.
    #>
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


    <#
    .SYNOPSIS
    Obtiene la ruta completa de un directorio en la lista de rutas.

    .DESCRIPTION
    Este método busca y devuelve la ruta completa de un directorio específico en la lista de rutas.

    .PARAMETER nameDir
    El nombre del directorio del cual se desea obtener la ruta.

    .RETURN
    Retorna la ruta completa del directorio si se encuentra en la lista, o 'null' si no se encuentra.
    #>
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

    <#
    .SYNOPSIS
    Obtiene un objeto PathItem correspondiente al directorio especificado.

    .DESCRIPTION
    Este método busca y devuelve un objeto PathItem correspondiente al directorio especificado en la lista de rutas.

    .PARAMETER nameDir
    El nombre del directorio del cual se desea obtener el objeto PathItem.

    .RETURN
    Retorna el objeto PathItem del directorio si se encuentra en la lista, o 'null' si no se encuentra.
    #>
    [PathItem] GetPathItem([string] $nameDir) {
        # Obtiene un objeto PathItem correspondiente al directorio especificado.
        # Retorna el objeto PathItem del directorio si se encuentra en la lista, o 'null' si no se encuentra.

        return $this.pathItems | Where-Object { $_.name -eq $nameDir }
    }

    <#
    .SYNOPSIS
    Verifica si existe un directorio con el nombre especificado en la lista de rutas.

    .DESCRIPTION
    Esta función verifica si ya existe un elemento con el mismo nombre de directorio en la lista de rutas.

    .PARAMETER nameDir
    El nombre del directorio que se desea verificar.

    .RETURN
    Retorna 'true' si existe un directorio con el nombre especificado en la lista, 'false' en caso contrario.
    #>
    [bool] isPathExists([string] $nameDir) {
        # Verifica si existe un directorio con el nombre especificado en la lista de rutas.
        # Retorna 'true' si existe un directorio con el nombre especificado en la lista, 'false' en caso contrario.

        return $this.GetPathItem($nameDir) | Measure-Object | Select-Object -ExpandProperty Count
    }


    <#
    .SYNOPSIS
    Verifica si existe un directorio con el nombre especificado en la lista de rutas.

    .DESCRIPTION
    Este método verifica si existe un elemento con el mismo nombre de directorio en la lista de rutas.

    .PARAMETER nameDir
    El nombre del directorio que se desea verificar.

    .RETURN
    Retorna 'true' si existe un directorio con el nombre especificado en la lista, 'false' en caso contrario.
    #>
    [bool] PathExists([string] $nameDir) {
        # Muestra la lista de rutas en la consola.

        $pathItem = $this.GetPathItem($nameDir)
        if ($null -ne $pathItem)
        {
            return $pathItem.isPathExists()
        }
        return $false
    }


    <#
    .SYNOPSIS
    Elimina un directorio de la lista de rutas.

    .DESCRIPTION
    Este método elimina un directorio de la lista de rutas.

    .PARAMETER nameDir
    El nombre del directorio que se desea eliminar.

    .RETURN
    Retorna 'true' si el directorio se eliminó exitosamente de la lista, 'false' si no se encontró.
    #>
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

    <#
    .SYNOPSIS
    Actualiza un directorio existente en la lista de rutas.

    .DESCRIPTION
    Este método verifica si el directorio especificado ya existe en la lista de rutas. Si existe, elimina el directorio utilizando el método DelPath y luego agrega el directorio de nuevo utilizando el método AddPath con los valores proporcionados. 

    .PARAMETER nameDir
    El nombre del directorio que se desea actualizar.

    .PARAMETER rootpath
    La nueva ruta raíz para construir la ruta completa del directorio.

    .PARAMETER showmsg
    Indica si se deben mostrar mensajes en la consola.

    .RETURN
    Retorna 'true' si el directorio se actualizó exitosamente, 'false' si no se encontró.
    #>
    [bool] UpdatePath([string] $nameDir, [string] $rootpath, [bool] $showmsg) {
        if ($this.isPathExists($nameDir))
        {
            $this.DelPath($nameDir)
        }
        return $this.AddPath($nameDir, $rootpath, $showmsg)
    }

    <#
    .SYNOPSIS
    Muestra la lista de rutas en la consola.

    .DESCRIPTION
    Este método muestra la lista de rutas en la consola, junto con los nombres y las rutas completas de los directorios.

    .EXAMPLE
    $pathList = [PathList]::new("C:\Root")
    $pathList.AddPath("dir1")
    $pathList.AddPath("dir2")
    $pathList.ShowPaths()
    #>
    [void] ShowPaths() {
        Write-Host "Lista de rutas:"
        foreach ($pathItem in $this.pathItems) {
            Write-Host "$($pathItem.name) : $($pathItem.GetPath())"
        }
    }
}
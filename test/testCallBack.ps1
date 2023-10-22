class MiClase {
    [string]$var
    [string]$opt
    [ScriptBlock]$callback

    MiClase() {
        $this.var = "Valor inicial de var"
        $this.opt = "Valor inicial de opt"
    }

    [void]Funcion1() {
        Write-Host "Var antes de llamar al callback: $($this.var)"
        Write-Host "Opt antes de llamar al callback: $($this.opt)"
        if ($null -ne $this.callback) {
            $prefix = "Prefijo: "
            $returnValue = $this.callback.Invoke($this, $prefix)
            Write-Host "Valor retornado por el callback: $returnValue"
        }
        Write-Host "Var después de llamar al callback: $($this.var)"
        Write-Host "Opt después de llamar al callback: $($this.opt)"
    }
}

class OtraClase {
    [hashtable] $list = @{
        "label" = "valor"
    }
    [ScriptBlock]ModificarVariables([MiClase]$objeto, [string]$prefix) {
        return {
            param($objeto, $prefix)
            if ($null -eq $objeto) {
                return
            }
            $objeto.var = "$prefix" + "Nuevo valor de var desde OtraClase"
            $objeto.opt = "$prefix" + "Nuevo valor de opt desde OtraClase"
            return ("Retorno del ScriptBlock: {0}" -f $this.list.count)
        }
    }
}

# Crear instancias de las clases
$miObjeto = [MiClase]::new()
$otraClase = [OtraClase]::new()

# Obtener el ScriptBlock del método de OtraClase y asignarlo como el callback
# $miObjeto.callback = $otraClase.ModificarVariables($miObjeto, "Prefijo Personalizado ")
$miObjeto.callback = $otraClase.ModificarVariables($null, $null)





# Llamar a la función que ejecuta el callback
$miObjeto.Funcion1()

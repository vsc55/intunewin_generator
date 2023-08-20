if (($null -eq $function:CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    Exit 1
}


class Config {
    
    $default = @{}
    $config  = @{}

    Config($defaultValues) {
        $this.default = $defaultValues;
        $this.config  = $this.default.Clone()
    }

    [bool] LoadConfig([string] $configFilePath)
    {
        if (Test-Path $configFilePath -PathType Leaf)
        {
            try
            {
                $jsonConfig = Get-Content -Raw -Path $configFilePath | ConvertFrom-Json
                foreach ($key in $jsonConfig.PSObject.Properties.Name)
                {
                    if ($this.config.ContainsKey($key))
                    {
                        $this.config[$key] = $jsonConfig.$key
                    }
                }
                return $true
            }
            catch
            {
                Write-Host ("Error reading JSON file: {0}" -f $_.Exception.Message) -ForegroundColor Red
            }
        }
        else
        {
            Write-Host ("El archivo no existe o no es un archivo válido.") -ForegroundColor Red
        }
        return $false
    }

    [bool] NewConfig([string] $option, [object] $defaultValue) {
        if (-not $this.default.ContainsKey($option))
        {
            $this.default.Add($option, $defaultValue)
            $this.config.Add($option, $defaultValue)
            return $true
        }
        return $false
    }

    [object] GetConfig([string] $option) {
        if ($this.config.ContainsKey($option)) {
            return $this.config[$option]
        }
        return $null
    }

    [void] SetConfig([string] $option, [object] $newValue) {
        if ($this.config.ContainsKey($option)) {
            $this.config[$option] = $newValue
        }
    }

    [bool] OptionExists([string] $option) {
        return $this.config.ContainsKey($option)
    }

    [object] GetDefaultValue([string] $option) {
        if ($this.default.ContainsKey($option)) {
            return $this.default[$option]
        }
        return $null
    }

    [bool] SaveConfig([string] $configFilePath) {
        try
        {
            $customConfig = @{}
            foreach ($key in $this.config.Keys) {
                if ($this.config[$key] -ne $this.defaultConfig[$key])
                {
                    $customConfig.Add($key, $this.config[$key])
                }
            }
            $customConfig | ConvertTo-Json | Set-Content -Path $configFilePath
            return $true
        }
        catch
        {
            Write-Host ("Error saving JSON file: {0}" -f $_.Exception.Message) -ForegroundColor Red
        }
        return $false
    }

    [void] ShowConfig() {
        Write-Host "Configuracion actual:" -ForegroundColor Yellow
        foreach ($key in $this.config.Keys)
        {
            $value        = $this.config[$key]
            $defaultValue = $this.default[$key]
            $formattedKey = $key.PadRight(20)
            if ($value -ne $defaultValue)
            {
                Write-Host "$formattedKey : $value" -ForegroundColor Green
            }
            else
            {
                Write-Host "$formattedKey : $value"
            }
        }
    }
}

# # Definir los valores por defecto en un hashtable
# $defaultValues = @{
#     "appName" = "AppName"
#     "appUninstallPath" = ""
#     "appUninstallArgs" = ""
#     "logFilePath" = "{{temp}}"
#     "logFileName" = "{{appName}}_process.txt"
#     "isOkCleanLog" = $false
#     "isOkRemoveLog" = $false
# }

# # Crear una instancia de la clase Config con los valores por defecto
# $config = [Config]::new($defaultValues)

# # Cargar configuración desde un archivo JSON
# $configFile = Join-Path $PSScriptRoot "config.json"
# $loadSuccess = $config.LoadConfig($configFile)

# if ($loadSuccess) {
#     Write-Host "Configuración cargada exitosamente."

#     # Obtener valores de configuración
#     $appName = $config.GetConfig("appName")
#     Write-Host "appName: $appName"

#     # Establecer un nuevo valor de configuración
#     $config.SetConfig("isOkCleanLog", $true)

#     # Comprobar si una opción existe
#     $optionExists = $config.OptionExists("logFilePath")
#     Write-Host "¿logFilePath existe?: $optionExists"

#     # Obtener valor por defecto
#     $defaultValue = $config.GetDefaultValue("logFileName")
#     Write-Host "Valor por defecto de logFileName: $defaultValue"

#     # Guardar la configuración en un nuevo archivo JSON
#     $saveSuccess = $config.SaveConfig(Join-Path $PSScriptRoot "nueva_config.json")
#     if ($saveSuccess) {
#         Write-Host "Configuración guardada exitosamente en nueva_config.json."
#     } else {
#         Write-Host "Error al guardar la configuración." -ForegroundColor Red
#     }
# } else {
#     Write-Host "Error al cargar la configuración." -ForegroundColor Red
# }
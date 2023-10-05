# https://github.com/MSEndpointMgr/IntuneWin32App/
# Pre-reqs = Install-Module MSGraph, IntuneWin32App, AzureAD, and PSIntuneAuth

if (($null -eq $function:CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    Exit 1
}

class intuneWin32AppCustom {

    [string]$TenantID = ""
    [bool]$enabled    = $true

    [bool]$TenantConnection = $false

    $InfoPublicSoftwareProp = @("label", "allowedValues", "defaultValue", "required")

    [Hashtable]$InfoPublicSoftware = @{
        "DisplayName" = @{
            "label"         = [string]"Nuevo Nombre de la Aplicación"
            "defaultValue"  = [string]""
            "required"      = $true
        };
        "Description" = @{
            "label"         = [string]"Nueva descripción de la aplicación"
            "defaultValue"  = [string]""
            "required"      = $true
        };
        "Publisher" = @{
            "label"         = [string]"Nuevo Publicador"
            "defaultValue"  = [string]""
            "required"      = $true
        };
        "Developer" = @{
            "label"         = [string]"Nuevo Desarrollador"
            "defaultValue"  = [string]""
            "required"      = $false
        };
        "Owner" = @{
            "label"         = [string]"Nuevo Propietario"
            "defaultValue"  = [string]""
            "required"      = $false
        };
        "InformationURL" = @{
            "label"         = [string]"Nueva URL de Información"
            "defaultValue"  = [string]""
            "allowedValues" = [string]"onlyurl"
            "required"      = $false
        };
        "PrivacyURL" = @{
            "label"         = [string]"Nueva URL de Privacidad"
            "defaultValue"  = [string]""
            "allowedValues" = [string]"onlyurl"
            "required"      = $false
        };
        "CompanyPortalFeaturedApp" = @{
            "label"         = [string]"¿Es una aplicación destacada en Company Portal? (true/false)"
            "allowedValues" = @("True", "False");
            "defaultValue"  = [string]"False"
            "required"      = $false
        };
        "InstallExperience" = @{
            "label"         = [string]"Experiencia de Instalación (system/user)"
            "allowedValues" = @("system", "user");
            "defaultValue"  = [string]"system"
            "required"      = $true
        };
        "RestartBehavior" =  @{
            "label"         = [string]"Comportamiento de Reinicio (allow/basedOnReturnCode/suppress/force)"
            "allowedValues" = @("allow", "basedOnReturnCode", "suppress", "force");
            "defaultValue"  = [string]"suppress"
            "required"      = $true
        };
        "InstallCommandLine" = @{
            "label"         = [string]"Nuevo Comando Instalacion"
            "defaultValue"  = [string]"install.cmd"
            "required"      = $true
        };
        "UninstallCommandLine" = @{
            "label"         = [string]"Nuevo Comando Desinstalacion"
            "defaultValue"  = [string]"uninstall.cmd"
            "required"      = $true
        };
        "Architecture" = @{
            "label"         = [string]"Nuevo Arquitectura soportada"
            "allowedValues" = @("x86", "x64", "All");
            "defaultValue"  = [string]"All"
            "required"      = $true
        };
        "MinimumSupportedWindowsRelease" = @{
            "label"         = [string]"Nuevo Version Minima de Windows soportada"
            "allowedValues" = @("W10_1607", "W10_1703", "W10_1709", "W10_1803", "W10_1809", "W10_1903", "W10_1909", "W10_2004", "W10_20H2", "W10_21H1", "W10_21H2", "W10_22H2", "W11_21H2", "W11_22H2");
            "defaultValue"  = [string]"W10_1607"
            "required"      = $true
        };
    }

    [string]$pathRootSoftware = ""






    intuneWin32AppCustom([string] $NewTenantID = "") {
        $this.SetTenantID($NewTenantID)
        # $this.CheckModulesDeps()
        
        $this.TenantConnection  = $false

        $this.SetEnabled($true)
        $this.SetRootPathSoftware("")
    }





    [void] SetEnabled([bool] $newEnabled) {
        $this.enabled = $newEnabled
    }
    [bool] GetEnabled () {
        return $this.enabled
    }
    [bool] GetIsEnabled () {
        if ([string]::IsNullOrEmpty($this.GetTenantID()))
        {
            return $false
        }
        return $this.GetEnabled()
    }






    [string] GetTenantID() {
        return $this.TenantID
    }
    [void] SetTenantID([string] $NewTenantID) {
        $this.TenantID = $NewTenantID
    }






    [bool] CheckModulesDeps([bool] $showMsg = $true, [bool] $yesInstall = $false){

        $dataReturn = $true

        $installModuleQuery = $null
        if ($yesInstall -eq $true)
        {
            $installModuleQuery = $true
        }


        $modulesDep = @("MSGraph", "IntuneWin32App", "AzureAD", "PSIntuneAuth")
        if ($showMsg) {
            Clear-Host
            Write-Host ("Comprobando dependencias:") -ForegroundColor Yellow
        }
        foreach ($module in $modulesDep) {

            if ($showMsg) {
                Write-Host ("Comprobando modulo '{0}'..." -f $module) -ForegroundColor Yellow -NoNewline
            }
            if (-not (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue))
            {
                if ($showMsg) {
                    Write-Host (" [No Instalado]") -ForegroundColor Red
                }

                if ($null -eq $installModuleQuery)
                {
                    $installModuleQuery = QueryYesNo -msg ("¿Deseas instalar el módulo '{0}'? (Y/N)" -f $module)
                }
                if ($installModuleQuery -eq $false)
                {
                    if ($showMsg) {
                        Write-Host ("Abortamos: El modulo '{0}' es necesario!" -f $module) -ForegroundColor Red
                    }
                    $dataReturn = $false
                    break
                }
                if ($showMsg) {
                    Write-Host ("Instalando el modulo '{0}'..." -f $module) -ForegroundColor Yellow  -NoNewline
                }
                try {
                    Install-Module -Name $module -Scope CurrentUser  -AcceptLicense -Force -ErrorAction Stop
                }
                catch
                {
                    # $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    if ($showMsg) {
                        Write-Host (" [Error]") -ForegroundColor Red
                        Write-Host ""
                        Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red
                    }
                    $dataReturn = $false
                    break
                }
                if ($showMsg) {
                    Write-Host (" [OK]") -ForegroundColor Green
                }
            }
            else
            {
                if ($showMsg) {
                    Write-Host (" [OK]") -ForegroundColor Green
                }
            }
        }
        if ($showMsg) {
            Write-Host ""
        }
        return $dataReturn
    }






    [bool] ConnectMSIntune([bool] $showMsg = $true) {
        $dataReturn = $true
        if ($this.GetIsEnabled() -eq $false)
        {
            if ($showMsg -eq $true)
            {
                Write-Host "MSIntune esta desactivado!!" -ForegroundColor Yellow
            }
            $dataReturn = $false
        }
        else
        {
            #Connect to Graph API - Commented out if running from master file. if running individually, uncomment below line.
            # $this.TenantConnection = ConnectTenantMSIntune -TenantID $this.Get-TenantID()

            if ($showMsg -eq $true) {
                Write-Host ("Conectando con el Tenant...") -ForegroundColor Green -NoNewline
            }
            
            try
            {
                $IntuneConnectWarnings = @()
                Connect-MSIntuneGraph -TenantID $this.GetTenantID() -WarningAction SilentlyContinue -WarningVariable IntuneConnectWarnings
                $this.TenantConnection = $true
                if ($IntuneConnectWarnings.Count -gt 0)
                {
                    if ($showMsg -eq $true) {
                        Write-Host (" [!!]") -ForegroundColor Yellow
                    }
                    :msgloop foreach ($IntuneConnectWarning in $IntuneConnectWarnings)
                    {
                        switch -Regex ($IntuneConnectWarning) {
                            ".*User canceled authentication.*" {
                                # An error occurred while attempting to retrieve or refresh access token. Error message: User canceled authentication.

                                if ($showMsg -eq $true) {
                                    Write-Host ("Error: Se canceló la autenticación durante la conexión a Microsoft Intune.") -ForegroundColor Red
                                }
                                $this.TenantConnection = $false
                                break msgloop
                            }
                            ".*Error message:*" {
                                if ($showMsg -eq $true) {
                                    Write-Host ("Error: {0}" -f $IntuneConnectWarning) -ForegroundColor Red
                                }
                                $this.TenantConnection = $false
                                break msgloop
                            }
                            default {
                                if ($showMsg -eq $true) {   
                                    Write-Host ("Advertencia: {0}" -f $IntuneConnectWarning) -ForegroundColor Yellow
                                }
                                Continue
                            }
                        }
                    }
                }
                else
                {
                    if ($showMsg -eq $true) {
                        Write-Host (" [OK]") -ForegroundColor Green
                    }
                }
                if ($showMsg -eq $true) {
                    Write-Host ""
                }
            }
            catch
            {
                # $Error[0].Exception.Message
                # $errCode     = $_.Exception.HResult
                $errMsg      = $_.Exception.Message
                $errLocation = $_.InvocationInfo.PositionMessage
                Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red
                Start-Sleep -Seconds 2
                
                $this.TenantConnection = $false
            }
            
            if ($this.TenantConnection -eq $false)
            {
                $dataReturn = $false
                if ($showMsg -eq $true) {
                    Write-Host "Se desactiva soporte Intune!!" -ForegroundColor Red
                }
                Start-Sleep -Seconds 5
            }
        }

        return $dataReturn
    }






    [void] SetRootPathSoftware([string] $newPath) {
        $this.pathRootSoftware = $newPath
    }
    [string] GetRootPathSoftware() {
        if ([string]::IsNullOrEmpty($this.pathRootSoftware))
        {
            return $null
        }
        return $this.pathRootSoftware
    }






    [string] GetPathFileInfoSoftwarePublic([string] $software, [string] $version) {
        
        $path = $this.GetRootPathSoftware()
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }
        $path = Join-Path $path $software
        if (-not [string]::IsNullOrEmpty($version))
        {
            $path = Join-Path $path "source"
            $path = Join-Path $path $version
        }
        $path = Join-Path $path "info.json"
        return $path
    }

    [bool] IsExistFileInfoSoftwarePublic([string] $software, [string] $version) {

        $softPathInfo = $this.GetPathFileInfoSoftwarePublic($software, $version)
        if ([string]::IsNullOrEmpty($softPathInfo) -and -not [string]::IsNullOrEmpty($version)) 
        {
            $softPathInfo = $this.GetPathFileInfoSoftwarePublic($software, "")
        }
        return -not [string]::IsNullOrEmpty($softPathInfo) -and (Test-Path -Path $softPathInfo -PathType Leaf)
    }

    [bool] SetDefaultConfigFileInfoSoftwarePubic([string] $software, [string] $version) {

        if ([string]::IsNullOrEmpty($software))
        {
            Write-Host ("SetDefaultConfigFileInfoSoftwarePubic: No se he defindo Software!") -ForegroundColor Red
            return $false
        }
        
        $softPathInfo = $this.GetPathFileInfoSoftwarePublic($software, $version)
        if ([string]::IsNullOrEmpty($softPathInfo))
        {
            Write-Host ("SetDefaultConfigFileInfoSoftwarePubic: No se ha obtenido path del archivo!") -ForegroundColor Red
            return $false
        }
        
        Write-Host ("El archivo '{0}' no existe, creando..." -f $softPathInfo) -ForegroundColor Yellow -NoNewline

        $jsonDefault = @{
            "Remplaces" = @{}
            "Win32App" = @{}
        }
        foreach ($prop in $this.InfoPublicSoftware.Keys)
        {
            switch -regex ($prop) {
                "(?i)DisplayName" {
                    $jsonDefault['Win32App'][$prop] = $software
                }
                "(?i)Description" {
                    $jsonDefault['Win32App'][$prop] = $software
                }
                "(?i)Publisher" {
                    $jsonDefault['Win32App'][$prop] = $software
                }
                default {
                    $jsonDefault['Win32App'][$prop] = $this.InfoPublicSoftware[$prop]["defaultValue"]
                }
            }
            Write-Host (".") -ForegroundColor Yellow -NoNewline
        }
                
        Try
        {
            $jsonDefaultString = $jsonDefault | ConvertTo-Json
            $jsonDefaultString | Set-Content -Path $softPathInfo
            Write-Host " [OK]" -ForegroundColor Green
            Write-Host ""
            return $true
        }
        catch
        {
            Write-Host " [Error]" -ForegroundColor Red
            # $errCode     = $_.Exception.HResult
            $errMsg      = $_.Exception.Message
            $errLocation = $_.InvocationInfo.PositionMessage
            Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red

            return $false
        }
    }

    [bool] CheckRequieredValues([hashtable] $Win32AppArgs) {
        $dataReturn = $true
        foreach ($key in $this.InfoPublicSoftware.Keys) {
            
            $required = $false
            if ($this.InfoPublicSoftware[$key].ContainsKey("required"))
            {
                $required = $this.InfoPublicSoftware[$key].required
            }
            
            if ($required -eq $true)
            {
                if ($Win32AppArgs.ContainsKey($key))
                {
                    $value = $Win32AppArgs[$key]
                    if ([string]::IsNullOrWhiteSpace($value))
                    {
                        $dataReturn = $false
                        break
                    }
                }
            }
        }
        return $dataReturn
    }

    [bool] EditFileInfoSoftwarePublic([string] $softPathInfo) {

        if ([string]::IsNullOrWhiteSpace($softPathInfo)) {
            return $false
        }

        try {
            # Cargamos la configuracion de info.json para ver si tenemos que editarla
            $jsonContent = Get-Content -Path $softPathInfo | Out-String
            $jsonObject = $jsonContent | ConvertFrom-Json
                
            do {
                foreach ($propiedad in $this.InfoPublicSoftware.Keys) {
                    $label         = $propiedad
                    $value         = ""
                    $allowedValues = $null
                    $defaultValue  = ""
                    $required      = $false

                    foreach ($input_prop in $this.InfoPublicSoftwareProp) {

                        if ($this.InfoPublicSoftware[$propiedad].ContainsKey($input_prop))
                        {
                            Set-Variable -Name $input_prop -Value $this.InfoPublicSoftware[$propiedad][$input_prop]   
                        }
                    }

                    if ($jsonObject.Win32App.PSObject.Properties[$propiedad] )
                    {
                        $value = $($jsonObject.Win32App.$propiedad)
                    }
                    else
                    {
                        # # Convertir Win32App en un objeto PSObject para permitir propiedades dinámicas
                        # $jsonObject.Win32App = New-Object PSObject -Property $jsonObject.Win32App

                        # Agregar la nueva propiedad al objeto
                        $jsonObject.Win32App | Add-Member -MemberType NoteProperty -Name $propiedad -Value $defaultValue
                    }


                    do {
                        Clear-Host
                        Write-Host ("{0}:" -f $label) -ForegroundColor Green
                        if ($required -eq $true)
                        {
                            Write-Host ("Campo Requeriado!") -ForegroundColor Yellow
                        }
                        if ($null -ne $allowedValues)
                        {
                            $allowedValuesString = ""
                            if ($allowedValues -is [string])
                            {
                                $allowedValuesString = $allowedValues
                            }
                            else
                            {
                                $allowedValuesString = $($allowedValues -join ', ')
                            }
                            Write-Host ("Valores permitidos: {0}" -f $allowedValuesString ) -ForegroundColor Yellow
                        }
                        Write-Host ("Valor   ({0})" -f $value) -ForegroundColor Green
                        Write-Host ("Default ({0})" -f $defaultValue) -ForegroundColor Green
                        Write-Host ""
                        $newValue = Read-Host ("Nuevo Valor, !! para valor por defecto")
                        
                        if ($newValue -eq "!!")
                        {
                            $newValue = $defaultValue
                        }
                        elseif ($required -eq $true)
                        {
                            if ([string]::IsNullOrWhiteSpace($newValue) -and [string]::IsNullOrWhiteSpace($value))
                            {
                                Write-Host ("Dato requerido!") -ForegroundColor Red
                                Continue
                            }
                            elseif ([string]::IsNullOrWhiteSpace($newValue) -and -not [string]::IsNullOrWhiteSpace($value))
                            {
                                $newValue = $value
                            }
                        }
                        elseif (-not [string]::IsNullOrWhiteSpace($allowedValues))
                        {
                            if ($allowedValues -eq "onlyurl")
                            {
                                if (-not [string]::IsNullOrWhiteSpace($newValue))
                                {
                                    $urlOk = Get-ValidarURL($newValue)
                                    if ($urlOk -eq $false) 
                                    {
                                        Write-Host ("Url No valida!") -ForegroundColor Red
                                        Continue
                                    }
                                }
                            }
                            elseif (-not [string]::IsNullOrWhiteSpace($newValue) -and $newValue -notin $allowedValues)
                            {
                                Write-Host ("Valor ({0}) no permitido. Los valores permitidos son: {1}" -f $newValue, $($allowedValues -join ', ') ) -ForegroundColor Red
                                Continue
                            }
                        }
                        if (-not [string]::IsNullOrWhiteSpace($newValue))
                        {
                            $value = $newValue
                        }
                        Write-Host ""
                        break
                    } while ($true)
                    
                    # Actualizar la propiedad en el objeto JSON
                    $jsonObject.Win32App.$propiedad = $value
                }

                Clear-Host
                Write-Host "Datos Nuevos:" -ForegroundColor Yellow
                Write-Host (Write-Output $jsonObject.Win32App | Format-List | Out-String)

                $queryEditAppInfoNewOK = QueryYesNo -msg "¿Los datos son correcots, Sí para guardar, No para volver a editar? (Y/N)"
                if ($queryEditAppInfoNewOK -eq $true)
                {
                    Write-Host ("Guardando cambios...") -ForegroundColor Yellow -NoNewline
                    $jsonContent = $jsonObject | ConvertTo-Json
                    $jsonContent | Set-Content -Path $softPathInfo
                    Write-Host (" [OK]") -ForegroundColor Green
                    break;
                }

            } while ($true)
        }
        catch
        {
            # $errCode     = $_.Exception.HResult
            $errMsg      = $_.Exception.Message
            $errLocation = $_.InvocationInfo.PositionMessage
            Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red
            return $false
        }
        return $true
    }

    [hashtable] ReadFileInfoSoftwarePubic([string] $software, [string] $version, [bool] $forzeEdit) {
        $dataReturn = @{
            "Remplaces" = @{}
            "Win32App"  = @{}
            "status"    = $false
            "error"     = @{
                "code"     = 0
                "msg"      = ""
                "location" = ""
            }
        }

        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            Write-Host ("Error ReadConfig: Faltan datos - Software ({0}), Version ({1}) !!" -f $software, $version) -ForegroundColor Red
        }
        else
        {
            $queryEditAppInfo = $false
            $newInfoJSON = $false

            if ($this.IsExistFileInfoSoftwarePublic($software, $version) -eq $true)
            {
                $softPathInfo = $this.GetPathFileInfoSoftwarePublic($software, $version)
            }
            else
            {
                $softPathInfo = $this.GetPathFileInfoSoftwarePublic($software, "")
                if (-not [string]::IsNullOrEmpty($softPathInfo))
                {
                    if (-not (Test-Path -Path $softPathInfo -PathType Leaf))
                    {
                        $this.SetDefaultConfigFileInfoSoftwarePubic($software, "")
                        $newInfoJSON = $true
                    }
                }
            }

            if (-not [string]::IsNullOrEmpty($softPathInfo) -and (Test-Path -Path $softPathInfo -PathType Leaf))
            {
                try
                {
                    $Win32AppArgs      = @{}
                    $Win32AppRemplaces = @{}

                    # Cargamos la configuracion de info.json para ver si tenemos que editarla
                    $jsonContent = Get-Content -Path $softPathInfo | Out-String
                    $jsonObject = $jsonContent | ConvertFrom-Json

                    if ($newInfoJSON -eq $false -and $forzeEdit -eq $false)
                    {
                        Clear-Host
                        Write-Host "Datos Actuales:" -ForegroundColor Yellow
                        Write-Host (Write-Output $jsonObject.Win32App | Format-List | Out-String)
                        $queryEditAppInfo = QueryYesNo -msg "¿Quieres editar algun dato? (Y/N)"
                        Write-Host ""
                    }
                    
                    if ($queryEditAppInfo -eq $true -or $newInfoJSON -eq $true -or $forzeEdit -eq $true)
                    {
                        $this.EditFileInfoSoftwarePublic($softPathInfo)
                    }
                    $jsonContent = $null
                    $jsonObject  = $null
    


                    # Cargamos la configuracion de info.json
                    $infoJsonContent = Get-Content -Raw -Path $softPathInfo | ConvertFrom-Json
                    if ($infoJsonContent.PSObject.Properties.Name -contains "Win32App")
                    {
                        $infoJsonContent.Win32App.PSObject.Properties | ForEach-Object {
                            $Win32AppArgs[$_.Name] = $_.Value
                        }
                    }
                    if ($infoJsonContent.PSObject.Properties.Name -contains "Remplaces")
                    {
                        $Win32AppRemplaces = $infoJsonContent.Remplaces
                    }
                    
                    $dataReturn = @{
                        "Remplaces" = $Win32AppRemplaces
                        "Win32App"  = $Win32AppArgs
                        "status"    = $true
                    }
                }
                catch
                {
                    $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    Write-Host ("{0} {1}" -f $errMsg, $errLocation) -ForegroundColor Red

                    $dataReturn["error"]["code"]     = $errCode
                    $dataReturn["error"]["msg"]      = $errMsg
                    $dataReturn["error"]["location"] = $errLocation
                }
            }
            else
            {
                $errMsg = ("File '{0}' not found. :(" -f $softPathInfo)
                Write-Host $errMsg -ForegroundColor Red

                $dataReturn["error"]["code"] = 1
                $dataReturn["error"]["msg"]  = $errMsg
            }
            
        }
        return $dataReturn
    }
    





    [string] GetPathLogoSoftware([string] $software, [string] $version) {

        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            return $null
        }

        $path = $this.GetRootPathSoftware()
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }

        $path = Join-Path $path $software
        if (-not [string]::IsNullOrEmpty($version))
        {
            $path = Join-Path $path "source"
            $path = Join-Path $path $version
        }
        
        $path = Join-Path $path "logo"
        $path = Join-Path $path "logo.png"
        return $path
    }



    [string] GetPathScriptDetect([string] $software, [string] $version) {

        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            return $null
        }

        $path = $this.GetRootPathSoftware()
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }

        $path = Join-Path $path $software
        $path = Join-Path $path "source"
        $path = Join-Path $path $version
        $path = Join-Path $path "scripts"
        $path = Join-Path $path "Detection_Script.ps1"
        return $path
    }




    # Check file intunewin exist
    # Comprobamos si el programa se ha publica ya en Intune
    # Return:
    #   False = No se ha publicado
    #   True  = Si se ha publicado
    #   Null  = Faltan datos
    [bool] CheckIfPublicSoftware([string] $software, [string] $version) {

        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            return $null
        }

        $Win32AppInfo = Get-IntuneWin32App -DisplayName $software | Where-Object { $_.displayVersion -eq $version }
        if ($null -eq $Win32AppInfo)
        {
            return $false
        }
        elseif ($Win32AppInfo -is [System.Object])
        {
            return $true
        }
        else
        {
            $formatoResult = ""
            if ($null -eq $Win32AppInfo)
            {
                $formatoResult = "Null"
            }
            elseif ($Win32AppInfo -is [int])
            {
                $formatoResult = "Int"
            }
            elseif ($Win32AppInfo -is [string])
            {
                $formatoResult = "String"
            }
            elseif ($Win32AppInfo -is [bool])
            {
                $formatoResult = "Bool"
            }
            elseif ($Win32AppInfo -is [double])
            {
                $formatoResult = "Double"
            }
            elseif ($Win32AppInfo -is [array])
            {
                $formatoResult = "Array"
            }
            elseif ($Win32AppInfo -is [Hashtable])
            {
                $formatoResult = "Hashtable"
            }
            elseif ($Win32AppInfo -is [DateTime])
            {
                $formatoResult = "DateTime"
            }
            else
            {
                $formatoResult = "Unknown"
            }
            return $formatoResult
        }
    }

    [bool] PublicSoftware([string] $software, [string] $version, [string] $fileIntuneWin)
    {
        if ($this.GetIsEnabled() -eq $false) {
            return $false
        }

        $configRead = $this.ReadFileInfoSoftwarePubic($software, $version, $false)
        if ($configRead['status'] -eq $false)
        {
            Write-Host ""
            Write-Host ("Proceso Abortado, error ({0}) : {1}" -f $configRead['error']['code'], $configRead['error']['msg']) -ForegroundColor Red
            Write-Host ""
            return $false
        }
        $Win32AppArgs      = $configRead['Win32App']
        $Win32AppRemplaces = $configRead['Remplaces']


        # Revisa si falta algun dato requerid
        while ($this.CheckRequieredValues($Win32AppArgs) -eq $false) {

            $queryEditAppInfoRequierdMissing = QueryYesNo -msg "¿Falta algun datos requerido, Sí para editar datos, No abortar publicacion? (Y/N)"
            Write-Host ""
            if ($queryEditAppInfoRequierdMissing -eq $true)
            {
                $configRead = $this.ReadFileInfoSoftwarePubic($software, $version, $true)
                if ($configRead['status'] -eq $true)
                {
                    $Win32AppArgs      = $configRead['Win32App']
                    $Win32AppRemplaces = $configRead['Remplaces']
                }
                else
                {
                    Write-Host ""
                    Write-Host ("Error ({0}) : {1}" -f $configRead['error']['code'], $configRead['error']['msg']) -ForegroundColor Red
                    Write-Host ""
                }
            }
            else
            {
                Write-Host ("Proceso Abortado!") -ForegroundColor Red
                Write-Host ""
                return $false
            }
        }



        $connect = $this.ConnectMSIntune($false)
        if ($connect -eq $false) {
            return $false
        }
        
       

        $Win32AppArgs['AppVersion']  = $version
        # $Win32AppArgs['DisplayName'] = "{0} {1}" -f $Win32AppArgs['DisplayName'], $Win32AppArgs['AppVersion']

        if ($Win32AppArgs.ContainsKey("PrivacyURL") -and [string]::IsNullOrWhiteSpace($Win32AppArgs["PrivacyURL"]))
        {
            $Win32AppArgs.Remove("PrivacyURL")
        }
        if ($Win32AppArgs.ContainsKey("InformationURL") -and [string]::IsNullOrWhiteSpace($Win32AppArgs["InformationURL"]))
        {
            $Win32AppArgs.Remove("InformationURL")
        }
        if ($Win32AppArgs.ContainsKey("Owner") -and [string]::IsNullOrWhiteSpace($Win32AppArgs["Owner"]))
        {
            $Win32AppArgs.Remove("Owner")
        }
        if ($Win32AppArgs.ContainsKey("Developer") -and [string]::IsNullOrWhiteSpace($Win32AppArgs["Developer"]))
        {
            $Win32AppArgs.Remove("Developer")
        }
        
        if ($Win32AppArgs.ContainsKey("CompanyPortalFeaturedApp"))
        {
            if ([string]::IsNullOrWhiteSpace($Win32AppArgs["CompanyPortalFeaturedApp"]))
            {
                $Win32AppArgs["CompanyPortalFeaturedApp"] = $false
            }
            else
            {
                $Win32AppArgs["CompanyPortalFeaturedApp"] = [System.Convert]::ToBoolean($Win32AppArgs["CompanyPortalFeaturedApp"])
            }
        }
        





        # Check file intunewin exist
        $Win32AppArgs['FilePath'] = $fileIntuneWin
        if (-not (Test-Path -Path $Win32AppArgs['FilePath'] -PathType Leaf))
        {
            Write-Host ("No se ha encontrado el archivo '{0}'" -f $Win32AppArgs['FilePath']) -ForegroundColor Red
            Write-Host ""
            Start-Sleep -Seconds 2
            return $false
        }
        
        

        $isPublicSoftware = $this.CheckIfPublicSoftware($software, $Win32AppArgs['AppVersion'])
        if ($null -eq $isPublicSoftware)
        {
            return $false
        }
        elseif ($isPublicSoftware -eq $true)
        {
            $Win32AppInfo = Get-IntuneWin32App -DisplayName $software | Where-Object { $_.displayVersion -eq $Win32AppArgs['AppVersion'] }

            if ($Win32AppInfo.PSObject.Properties.Match('Count').Count -gt 0)
            {
                Write-Host ("Se ha encontrado esta version de la app repetida {0} veces. Echa un ojo a ver que esta pasa!" -f $Win32AppInfo.Count) -ForegroundColor Red
                Write-Host ""
                Get-IntuneWin32App -DisplayName $software | Where-Object { $_.displayVersion -eq $Win32AppArgs['AppVersion'] } | Select-Object -Property displayName, displayVersion, id, createdDateTime | Sort-Object -Property createdDateTime
            }
            elseif ($Win32AppInfo.PSObject.Properties.Match('id').Count -gt 0)
            {
                Write-Host ("Actualizando PackageFile de la App [{0} {1}]..." -f $software, $Win32AppArgs['AppVersion']) -ForegroundColor Green
                Update-IntuneWin32AppPackageFile -ID $Win32AppInfo.id -FilePath $Win32AppArgs['FilePath']
                Write-Host ("Actualizcion completa!") -ForegroundColor Green
                Write-Host ""
                Start-Sleep -Seconds 2
                return $true
            }
            else
            {
                Write-Host ("Actualizando PackageFile abortada, no se detecto ID!") -ForegroundColor Red
            }
            Write-Host ""
            Start-Sleep -Seconds 2
            return $false
        }
        elseif ($isPublicSoftware -eq $false)
        {
            # Check Script Detecction
            $softVerScriptDetection = $this.GetPathScriptDetect($software, $Win32AppArgs['AppVersion'])
            if (-not (Test-Path -Path $softVerScriptDetection -PathType Leaf))
            {
                Write-Host ("No se ha encontrado el script de deteccion [{0}]!" -f $softVerScriptDetection) -ForegroundColor Red
                Write-Host ""
                Start-Sleep -Seconds 2
                return $false
            }


            # Create Logo
            $softFileLogo = $this.GetPathLogoSoftware($software, $Win32AppArgs['AppVersion'])
            if (-not (Test-Path -Path $softFileLogo -PathType Leaf))
            {
                $softFileLogo = $this.GetPathLogoSoftware($software, "")
            }

            if (-not [string]::IsNullOrEmpty($softFileLogo) -and (Test-Path -Path $softFileLogo -PathType Leaf))
            {
                $Win32AppArgs['Icon'] = New-IntuneWin32AppIcon -FilePath $softFileLogo
            }
            else
            {
                $softFileLogo = $null
                Write-Host ("No se detecto logo") -ForegroundColor Yellow
                Write-Host ""
            }

              

            # Create Requirement Rule
            $Win32AppRequirementRule = @{
                'Architecture'                   = $Win32AppArgs['Architecture']
                'MinimumSupportedWindowsRelease' = $Win32AppArgs['MinimumSupportedWindowsRelease']
            }
            $Win32AppArgs['RequirementRule'] = New-IntuneWin32AppRequirementRule @Win32AppRequirementRule
            $Win32AppArgs.Remove("Architecture")
            $Win32AppArgs.Remove("MinimumSupportedWindowsRelease")



            
          
            # Detection rules
            $Win32AppDetectionRuleScript = @{
                'ScriptFile'            = $softVerScriptDetection
                'EnforceSignatureCheck' = $false
                'RunAs32Bit'            = $false
            }
            $Win32AppArgs['DetectionRule'] = New-IntuneWin32AppDetectionRuleScript @Win32AppDetectionRuleScript




            # Create custom return code
            # $ReturnCode = New-IntuneWin32AppReturnCode -ReturnCode 1337 -Type retry
            # $Win32AppArgs['ReturnCode'] = $ReturnCode




            Write-Host ("Publicando App [{0} {1}]..." -f $Win32AppArgs['DisplayName'], $Win32AppArgs['AppVersion']) -ForegroundColor Green
            Add-IntuneWin32App @Win32AppArgs
            Write-Host ("Publicacion completa!") -ForegroundColor Green
            Write-Host ""
            Start-Sleep -Seconds 2
        



            # Update Old Version
            # if ($Win32AppRemplaces.PSObject.Properties.Name -contains $Win32AppArgs['AppVersion'])
            # {
            #     $OldAppVersion = $Win32AppRemplaces.PSObject.Properties[$Win32AppArgs['AppVersion']].Value
                
            #     Write-Host ("Asignando sustitucion de version ({0}) por ({1})..." -f $OldAppVersion, $Win32AppArgs['AppVersion']) -ForegroundColor Green

            #     $Win32AppLatest   = Get-IntuneWin32App -DisplayName $Win32AppArgs['DisplayName'] | Where-Object { $_.displayVersion -eq $Win32AppArgs['AppVersion'] }
            #     $Win32AppPrevious = Get-IntuneWin32App -DisplayName $Win32AppArgs['DisplayName'] | Where-Object { $_.displayVersion -eq $OldAppVersion }

            #     $AllowSupersedence = $true
            #     if ($Win32AppLatest -is [System.Object])
            #     {
            #         if ($Win32AppLatest.PSObject.Properties.Match('Count').Count -gt 0)
            #         {
            #             $AllowSupersedence = $false
            #             Write-Host ("Se ha encontrado esta version de la app repetida {0} veces. Echa un ojo a ver que esta pasa!" -f $Win32AppLatest.Count) -ForegroundColor Red
            #             Write-Host ""
            #             Get-IntuneWin32App -DisplayName $Win32AppArgs['DisplayName'] | Where-Object { $_.displayVersion -eq $Win32AppArgs['AppVersion'] } | Select-Object -Property displayName, displayVersion, id, createdDateTime | Sort-Object -Property createdDateTime
            #             Write-Host ""
            #         }
            #     }
            #     if ($AllowSupersedence -eq $true)
            #     {
            #         $Supersedence = New-IntuneWin32AppSupersedence -ID $Win32AppPrevious.id -SupersedenceType "Replace" # Replace for uninstall, Update for updating
            #         Add-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Supersedence $Supersedence
            #         # Get-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Verbose
            #         # Remove-IntuneWin32AppSupersedence -ID $Win32AppLatest.id -Verbose

            #         Write-Host ("Sustitucion completa!") -ForegroundColor Green
            #         Write-Host ""        
            #     }
            #     Start-Sleep -Seconds 2
            # }
            
            return $true
        }
        else
        {
            Write-Host ("Formato no valido [{0}] en la deteccion de si existe el pakete en Intune!" -f $isPublicSoftware) -ForegroundColor Red
            Write-Host ""
            Start-Sleep -Seconds 2
            return $false
        }
        return $false
    }


}
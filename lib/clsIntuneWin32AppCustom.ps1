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

    [string]$pathRootSoftware = ""

    [string]$TenantID         = ""
    [bool]$TenantConnection   = $false

    [bool]$enabled            = $true
    [string]$OSType           = $null

    [string]$PathSoftOut      = "out"
    [string]$PathSoftSource   = "source"
    [string]$PathSoftLogo     = "logo"
    [string]$PathSoftScript   = "scripts"

    [string]$NameFileLogo     = "Logo.png"
    [string]$NameFileDetect   = "Detection_Script.ps1"
    [string]$NameFileInfoJSON = "info.json"

    [string[]]$necessaryModules        = @("MSGraph", "IntuneWin32App", "AzureAD", "PSIntuneAuth")
    [string[]]$InfoPublishSoftwareProp = @("label", "allowedValues", "defaultValue", "required")

    [Hashtable]$InfoPublishSoftware = @{
        "DisplayName" = @{
            "label"         = [string]"Nuevo Nombre de la Aplicación"
            "defaultValue"  = [string]""
            "required"      = $true
        }
        "Description" = @{
            "label"         = [string]"Nueva descripción de la aplicación"
            "defaultValue"  = [string]""
            "required"      = $true
        }
        "Publisher" = @{
            "label"         = [string]"Nuevo Publicador"
            "defaultValue"  = [string]""
            "required"      = $true
        }
        "Developer" = @{
            "label"         = [string]"Nuevo Desarrollador"
            "defaultValue"  = [string]""
            "required"      = $false
        }
        "Owner" = @{
            "label"         = [string]"Nuevo Propietario"
            "defaultValue"  = [string]""
            "required"      = $false
        }
        "InformationURL" = @{
            "label"         = [string]"Nueva URL de Información"
            "defaultValue"  = [string]""
            "allowedValues" = [string]"onlyurl"
            "required"      = $false
        }
        "PrivacyURL" = @{
            "label"         = [string]"Nueva URL de Privacidad"
            "defaultValue"  = [string]""
            "allowedValues" = [string]"onlyurl"
            "required"      = $false
        }
        "CompanyPortalFeaturedApp" = @{
            "label"         = [string]"¿Es una aplicación destacada en Company Portal? (true/false)"
            "allowedValues" = @("True", "False");
            "defaultValue"  = [string]"False"
            "required"      = $false
        }
        "InstallExperience" = @{
            "label"         = [string]"Experiencia de Instalación (system/user)"
            "allowedValues" = @("system", "user");
            "defaultValue"  = [string]"system"
            "required"      = $true
        }
        "RestartBehavior" =  @{
            "label"         = [string]"Comportamiento de Reinicio (allow/basedOnReturnCode/suppress/force)"
            "allowedValues" = @("allow", "basedOnReturnCode", "suppress", "force");
            "defaultValue"  = [string]"suppress"
            "required"      = $true
        }
        "InstallCommandLine" = @{
            "label"         = [string]"Nuevo Comando Instalacion"
            "defaultValue"  = [string]"install.cmd"
            "required"      = $true
        }
        "UninstallCommandLine" = @{
            "label"         = [string]"Nuevo Comando Desinstalacion"
            "defaultValue"  = [string]"uninstall.cmd"
            "required"      = $true
        }
        "Architecture" = @{
            "label"         = [string]"Nuevo Arquitectura soportada"
            "allowedValues" = @("x86", "x64", "All");
            "defaultValue"  = [string]"All"
            "required"      = $true
        }
        "MinimumSupportedWindowsRelease" = @{
            "label"         = [string]"Nuevo Version Minima de Windows soportada"
            "allowedValues" = @("W10_1607", "W10_1703", "W10_1709", "W10_1803", "W10_1809", "W10_1903", "W10_1909", "W10_2004", "W10_20H2", "W10_21H1", "W10_21H2", "W10_22H2", "W11_21H2", "W11_22H2");
            "defaultValue"  = [string]"W10_1607"
            "required"      = $true
        }
    }

    

    
    intuneWin32AppCustom([string] $NewTenantID = "") {
        <#
        .SYNOPSIS
            Constructor de la clase IntuneWin32AppCustom.

        .DESCRIPTION
            Este constructor inicializa una nueva instancia de la clase IntuneWin32AppCustom.

        .PARAMETER NewTenantID
            Parámetro opcional que representa el ID del inquilino. Por defecto, se establece en una cadena vacía ("").

        .NOTES
            Este constructor se utiliza para crear una nueva instancia de la clase IntuneWin32AppCustom.
            Inicializa la conexión al inquilino como deshabilitada, establece el ID del inquilino, habilita la instancia y establece la ruta raíz del software en una cadena vacía.
        #>

        $this.TenantConnection = $false
        $this.OSType           = $this.GetCurrentSO()

        $this.SetTenantID($NewTenantID)
        $this.SetEnabled($true)
        $this.SetRootPathSoftware("")
    }



    
    [void] SetEnabled([bool] $newEnabled) {
        <#
        .SYNOPSIS
            Establece el estado habilitado del objeto.

        .DESCRIPTION
            Este método permite establecer el estado habilitado del objeto.

        .PARAMETER newEnabled
            Parámetro que indica el nuevo estado habilitado (booleano) del objeto.

        .NOTES
            El método no tiene salida, simplemente actualiza el estado habilitado del objeto.
        #>
        $this.enabled = $newEnabled
    }

    [bool] GetEnabled () {
        <#
        .SYNOPSIS
            Obtiene el estado habilitado actual del objeto.

        .DESCRIPTION
            Este método devuelve el estado habilitado actual del objeto.

        .OUTPUTS
            Devuelve el estado habilitado (booleano) del objeto.
        #>
        return $this.enabled
    }

    [bool] GetIsEnabled () {
        <#
        .SYNOPSIS
            Verifica si el objeto está habilitado.

        .DESCRIPTION
            Este método verifica si el objeto está habilitado. Retorna $true si el objeto tiene un ID del inquilino y está habilitado, de lo contrario, retorna $false.

        .OUTPUTS
            Devuelve el estado habilitado (booleano) del objeto.
        #>
        if ([string]::IsNullOrEmpty($this.GetTenantID()))
        {
            return $false
        }
        return $this.GetEnabled()
    }



    
    [string] GetTenantID() {
        <#
        .SYNOPSIS
            Obtiene el ID del inquilino.

        .DESCRIPTION
            Este método devuelve el ID del inquilino actual.

        .OUTPUTS
            Devuelve el ID del inquilino como una cadena de texto.
        #>
        return $this.TenantID
    }

    [void] SetTenantID([string] $NewTenantID) {
        <#
        .SYNOPSIS
            Establece el ID del inquilino.

        .DESCRIPTION
            Este método permite establecer el ID del inquilino con un nuevo valor proporcionado.

        .PARAMETER NewTenantID
            Parámetro que representa el nuevo ID del inquilino.

        .NOTES
            El método no tiene salida y simplemente actualiza el ID del inquilino.
        #>
        $this.TenantID = $NewTenantID
    }




    [bool] CheckModulesDeps([bool] $showMsg = $true, [bool] $yesInstall = $false){
        <#
        .SYNOPSIS
            Verifica las dependencias de los módulos necesarios.

        .DESCRIPTION
            Este método verifica si los módulos especificados están instalados y, si no lo están,
            ofrece al usuario la opción de instalarlos. Devuelve $true si todas las dependencias están
            satisfechas, de lo contrario, devuelve $false.

        .PARAMETER showMsg
            Parámetro opcional que indica si mostrar mensajes durante la verificación de dependencias.
            Por defecto, se establece en $true.

        .PARAMETER yesInstall
            Parámetro opcional que indica si instalar automáticamente los módulos faltantes.
            Por defecto, se establece en $false.

        .OUTPUTS
            Devuelve $true si todas las dependencias están satisfechas, de lo contrario, devuelve $false.
        #>
        $dataReturn = $true

        $installModuleQuery = $null
        if ($yesInstall -eq $true)
        {
            $installModuleQuery = $true
        }

        Import-Module PowerShellGet
        if ($showMsg) {
            # Clear-Host
            Write-Host ("Checking Dependencies...") -ForegroundColor Yellow
        }
        foreach ($module in $this.necessaryModules) {

            if ($showMsg) {
                Write-Host ("- Module '{0}'..." -f $module) -ForegroundColor Yellow -NoNewline
            }
            if (-not (Get-InstalledModule -Name $module -ErrorAction SilentlyContinue))
            {
                if ($showMsg) {
                    Write-Host (" [X]") -ForegroundColor Red
                }

                if ($null -eq $installModuleQuery)
                {
                    Write-Host ""
                    $installModuleQuery = QueryYesNo -Msg ("Do you want to Install the '{0}' Module?" -f $module) -ForegroundColor DarkYellow
                }
                if ($installModuleQuery -eq $false)
                {
                    if ($showMsg) {
                        Write-Host ("Abort: Module '{0}' is necessary!" -f $module) -ForegroundColor Red
                    }
                    $dataReturn = $false
                    break
                }
                if ($showMsg) {
                    Write-Host ("Installing Module '{0}'..." -f $module) -ForegroundColor Yellow  -NoNewline
                }
                try {
                    Install-Module -Name $module -Scope CurrentUser  -AcceptLicense -Force -ErrorAction Stop
                }
                catch
                {
                    $dataReturn = $false

                    if ($showMsg)
                    {
                        $errCode     = $_.Exception.HResult
                        $errMsg      = $_.Exception.Message
                        $errLocation = $_.InvocationInfo.PositionMessage

                        Write-Host (" [X]") -ForegroundColor Red
                        Write-Host ""
                        Write-Host ("Code Error '{0}' - Error: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red
                    }
                    break
                }
                if ($showMsg) {
                    Write-Host (" [√]") -ForegroundColor Green
                }
            }
            else
            {
                if ($showMsg) {
                    Write-Host (" [√]") -ForegroundColor Green
                }
            }
        }
        if ($showMsg) {
            Write-Host ""
        }
        return $dataReturn
    }




    [bool] ConnectMSIntune([bool] $showMsg = $true) {
        <#
        .SYNOPSIS
            Conecta con Microsoft Intune.

        .DESCRIPTION
            Este método intenta establecer una conexión con Microsoft Intune y devuelve verdadero si la conexión es
            exitosa y si Intune está habilitado. Devuelve falso si la conexión falla o si Intune está deshabilitado.

        .PARAMETER showMsg
            Parámetro opcional que indica si mostrar mensajes durante el proceso de conexión.
            Por defecto, se establece en $true.

        .OUTPUTS
            Devuelve $true si la conexión es exitosa y si Intune está habilitado, de lo contrario, devuelve $false.
        #>
        $dataReturn = $true
        if ($this.GetIsEnabled() -eq $false)
        {
            if ($showMsg)
            {
                Write-Host "MSIntune is disabled!!" -ForegroundColor Yellow
            }
            $dataReturn = $false
        }
        else
        {
            if ($showMsg)
            {
                Write-Host ("Connecting with the Tenant ({0})..." -f $this.TenantID) -ForegroundColor Green -NoNewline
            }
            try
            {
                $IntuneConnectWarnings = @()
                Connect-MSIntuneGraph -TenantID $this.GetTenantID() -WarningAction SilentlyContinue -WarningVariable IntuneConnectWarnings
                $this.TenantConnection = $true
                if ($IntuneConnectWarnings.Count -gt 0)
                {
                    if ($showMsg) {
                        Write-Host (" [!!]") -ForegroundColor Yellow
                    }
                    :msgloop foreach ($IntuneConnectWarning in $IntuneConnectWarnings)
                    {
                        switch -Regex ($IntuneConnectWarning) {
                            ".*User canceled authentication.*" {
                                # An error occurred while attempting to retrieve or refresh access token. Error message: User canceled authentication.
                                if ($showMsg) {
                                    Write-Host ("Error: Authentication was canceled while connecting to Microsoft Intune.") -ForegroundColor Red
                                }
                                $this.TenantConnection = $false
                                break msgloop
                            }
                            ".*Error message:*" {
                                if ($showMsg) {
                                    Write-Host ("Error: {0}" -f $IntuneConnectWarning) -ForegroundColor Red
                                }
                                $this.TenantConnection = $false
                                break msgloop
                            }
                            default {
                                if ($showMsg) {
                                    Write-Host ("Warning: {0}" -f $IntuneConnectWarning) -ForegroundColor Yellow
                                }
                                Continue
                            }
                        }
                    }
                }
                else
                {
                    if ($showMsg) {
                        Write-Host (" [OK]") -ForegroundColor Green
                    }
                }
            }
            catch
            {
                $this.TenantConnection = $false

                if ($showMsg)
                {
                    $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    Write-Host (" [X]") -ForegroundColor Red
                    Write-Host ("Code Error '{0}' - Error: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red
                    Write-Host ""
                }
            }
            
            if ($this.TenantConnection -eq $false)
            {
                $dataReturn = $false
                if ($showMsg) {
                    Write-Host "Intune support is disabled!!" -ForegroundColor Red
                }
            }

            if ($showMsg) {
                Write-Host ""
            }
        }

        return $dataReturn
    }




    [void] SetRootPathSoftware([string] $newPath) {
        <#
        .SYNOPSIS
            Establece la ruta raíz del software con la ruta proporcionada como argumento.

        .DESCRIPTION
            Esta función permite establecer la ruta raíz del software con la ruta proporcionada como
            argumento. La ruta se asigna a la propiedad 'pathRootSoftware' del objeto actual.

        .PARAMETER newPath
            Nuevo camino que se utilizará como ruta raíz del software.

        .NOTES
            Esta función no tiene salida; simplemente actualiza la propiedad 'pathRootSoftware' del objeto actual.
        #>
        $this.pathRootSoftware = $newPath
    }

    [string] GetRootPathSoftware() {
        <#
        .SYNOPSIS
            Obtiene la ruta raíz del software.

        .DESCRIPTION
            Esta función permite obtener la ruta raíz del software. Verifica si la propiedad 'pathRootSoftware' del
            objeto actual está definida. Si está vacía o nula, devuelve $null; de lo contrario, devuelve la ruta
            raíz del software.

        .OUTPUTS
            Esta función retorna la ruta raíz del software si está definida en la propiedad 'pathRootSoftware'; de 
            lo contrario, devuelve $null.
        #>
        if ([string]::IsNullOrEmpty($this.pathRootSoftware))
        {
            return $null
        }
        return $this.pathRootSoftware
    }

    [string] GetIsRootPathSoftwareExist() {
        <#
        .SYNOPSIS
            Verifica si el directorio raíz del software existe y es un directorio válido.

        .DESCRIPTION
            Esta función comprueba si el directorio raíz del software está especificado y si existe como un
            directorio válido en el sistema de archivos.

        .OUTPUTS
            Devuelve un valor booleano (true o false) que indica si el directorio raíz del software existe y es un directorio válido.
        #>
        $rootPath = $this.GetRootPathSoftware()
        if ([string]::IsNullOrEmpty($rootPath) -or -not (Test-Path -Path $rootPath -PathType Container))
        {
            return $false
        }
        return $true
    }

    [string] GetOutPath([string] $software){
        <#
        .SYNOPSIS
            Define un método llamado GetOutPath que construye una ruta de salida.

        .DESCRIPTION
            El método GetOutPath toma la ruta raíz del software y el nombre de la carpeta de salida (almacenado en $this.PathSoftOut) para
            construir una ruta de salida completa. Si la ruta raíz del software o el nombre de la carpeta de salida están vacíos, el 
            método devuelve $null.

        .PARAMETER software
            Nombre del software.

        .OUTPUTS
            [String] El método devuelve una cadena que representa la ruta de salida completa para el software. Si la función no puede construir
            la ruta de salida, devuelve $null.
        #>
        $path = $this.GetRootPathSoftware()
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }
        $path = Join-Path $path $software
        $path = Join-Path $path $this.PathSoftOut
        return $path
    }
    


    [string] GetPathFileInfoSoftwarePublish([string] $software, [string] $version) {
        <#
        .SYNOPSIS
            Obtiene la ruta del archivo "info.json" del software especificado.

        .DESCRIPTION
            Esta función construye y devuelve la ruta completa del archivo "info.json" para el
            software especificado y su versión (si se proporciona).

        .PARAMETER $software
            Nombre del software.

        .PARAMETER $version
            Número de versión del software (opcional).

        .OUTPUTS
            [string] Ruta completa del archivo "info.json" del software especificado. Retorna $null si la 
            ruta no puede ser construida.
        #>
        if ($this.GetIsRootPathSoftwareExist() -eq $false -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }
        $path = $this.GetRootPathSoftware()
        $path = Join-Path $path $software
        if (-not [string]::IsNullOrEmpty($version))
        {
            $path = Join-Path $path $this.PathSoftSource 
            $path = Join-Path $path $version
        }
        $path = Join-Path $path $this.NameFileInfoJSON
        return $path
    }

    [bool] IsExistFileInfoSoftwarePublish([string] $software, [string] $version) {
        <#
        .SYNOPSIS
            Verifica si existe el archivo "info.json" para el software y la versión especificados.

        .DESCRIPTION
            Esta función verifica si el archivo "info.json" para el software y la versión especificados 
            existe en el sistema de archivos.

        .PARAMETER $software
            Nombre del software.

        .PARAMETER $version
            Número de versión del software (opcional).

        .OUTPUTS
            [bool] Verdadero si el archivo "info.json" existe, falso de lo contrario.
        #>

        $softPathInfo = $this.GetPathFileInfoSoftwarePublish($software, $version)
        if ([string]::IsNullOrEmpty($softPathInfo) -and -not [string]::IsNullOrEmpty($version)) 
        {
            $softPathInfo = $this.GetPathFileInfoSoftwarePublish($software, "")
        }
        return -not [string]::IsNullOrEmpty($softPathInfo) -and (Test-Path -Path $softPathInfo -PathType Leaf)
    }

    [bool] SetDefaultConfigFileInfoSoftwarePubic([string] $software, [string] $version) {
        <#
        .SYNOPSIS
            Establece la configuración predeterminada para el archivo "info.json" del software 
            especificado y su versión.

        .DESCRIPTION
            Esta función establece la configuración predeterminada para el archivo "info.json" del
            software especificado y su versión (si se proporciona).

        .PARAMETER $software
            Nombre del software.

        .PARAMETER $version
            Número de versión del software (opcional).

        .OUTPUTS
            [bool] Verdadero si se establece la configuración predeterminada con éxito, falso de lo contrario.
        #>
        $dataReturn = $false
        if ([string]::IsNullOrEmpty($software))
        {
            Write-Host ("SetDefaultConfigFileInfoSoftwarePubic: Software is missing!") -ForegroundColor Red
        }
        else
        {
            $softPathInfo = $this.GetPathFileInfoSoftwarePublish($software, $version)
            if ([string]::IsNullOrEmpty($softPathInfo))
            {
                Write-Host ("SetDefaultConfigFileInfoSoftwarePubic: File path is null!") -ForegroundColor Red
            }
            else
            {
                Write-Host ("File '{0}' does not exist, creating..." -f $softPathInfo) -ForegroundColor Yellow -NoNewline
                $jsonDefault = @{
                    "Options"   = @{
                        "Type" = "Win32App"
                    }
                    "Remplaces" = @{}
                    "Win32App"  = @{}
                    "MSI"       = @{}
                }
                foreach ($prop in $this.InfoPublishSoftware.Keys)
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
                            $jsonDefault['Win32App'][$prop] = $this.InfoPublishSoftware[$prop]["defaultValue"]
                        }
                    }
                    Write-Host (".") -ForegroundColor Yellow -NoNewline
                }
                Try
                {
                    $jsonDefaultString = $jsonDefault | ConvertTo-Json
                    $jsonDefaultString | Set-Content -Path $softPathInfo
                    Write-Host (" [√]") -ForegroundColor Green
                    $dataReturn = $true
                }
                catch
                {
                    $dataReturn  = $false
                    $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    Write-Host (" [X]") -ForegroundColor Red
                    Write-Host ("Code Error '{0}' - Error: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red
                }
                Write-Host ""
            }
        }
        return $dataReturn
    }

    [bool] CheckRequieredValues([hashtable] $Win32AppArgs) {
        <#
        .SYNOPSIS
            Verifica si los valores requeridos están presentes y no son nulos o cadenas vacías en el
            hashtable proporcionado.

        .DESCRIPTION
            Esta función verifica si los valores requeridos para las claves especificadas en InfoPublishSoftware
            están presentes en el hashtable proporcionado.

        .PARAMETER $Win32AppArgs
            Hashtable que contiene los argumentos del software Win32.

        .OUTPUTS
            [bool] Verdadero si todos los valores requeridos están presentes y no son nulos o cadenas vacías,
            falso de lo contrario.
        #>
        $dataReturn = $true
        foreach ($key in $this.InfoPublishSoftware.Keys) {
            
            $required = $false
            if ($this.InfoPublishSoftware[$key].ContainsKey("required"))
            {
                $required = $this.InfoPublishSoftware[$key].required
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

    [bool] EditFileInfoSoftwarePublish([string] $softPathInfo) {
        <#
        .SYNOPSIS
            Edita el archivo de configuración JSON del software Win32.

        .DESCRIPTION
            Esta función permite editar las propiedades del software Win32 en el archivo de
            configuración JSON especificado.

        .PARAMETER $softPathInfo
            La ruta del archivo de configuración JSON del software Win32.

        .OUTPUTS
            [bool] Verdadero si la edición se realizó correctamente, falso si ocurrió un error.
        #>
        $dataReturn = $false
        if (-not [string]::IsNullOrWhiteSpace($softPathInfo))
        {
            try {
                # Cargamos la configuracion de info.json para ver si tenemos que editarla
                $jsonContent = Get-Content -Path $softPathInfo | Out-String
                $jsonObject = $jsonContent | ConvertFrom-Json
                    
                do {
                    foreach ($propiedad in $this.InfoPublishSoftware.Keys) {
                        $label         = $propiedad
                        $value         = ""
                        $allowedValues = $null
                        $defaultValue  = ""
                        $required      = $false

                        foreach ($input_prop in $this.InfoPublishSoftwareProp) {
                            if ($this.InfoPublishSoftware[$propiedad].ContainsKey($input_prop))
                            {
                                Set-Variable -Name $input_prop -Value $this.InfoPublishSoftware[$propiedad][$input_prop]   
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
                                Write-Host ("Required!") -ForegroundColor Red
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
                                Write-Host ("Allowed Values: {0}" -f $allowedValuesString ) -ForegroundColor Yellow
                            }
                            Write-Host ("Value   ({0})" -f $value) -ForegroundColor Green
                            Write-Host ("Default ({0})" -f $defaultValue) -ForegroundColor Green
                            Write-Host ""
                            $newValue = Read-Host ("New Value, !! for default value")
                            
                            if ($newValue -eq "!!")
                            {
                                $newValue = $defaultValue
                            }
                            elseif ($required -eq $true)
                            {
                                if ([string]::IsNullOrWhiteSpace($newValue) -and [string]::IsNullOrWhiteSpace($value))
                                {
                                    Write-Host ("Error, Required Data!") -ForegroundColor Red
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
                                            Write-Host ("Invalid URL!") -ForegroundColor Red
                                            Continue
                                        }
                                    }
                                }
                                elseif (-not [string]::IsNullOrWhiteSpace($newValue) -and $newValue -notin $allowedValues)
                                {
                                    Write-Host ("Value '{0}' not allowed. The allowed values ​​are: {1}" -f $newValue, $($allowedValues -join ', ') ) -ForegroundColor Red
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
                    Write-Host "New Data:" -ForegroundColor Yellow
                    Write-Host (Write-Output $jsonObject.Win32App | Format-List | Out-String)


                    if ((QueryYesNo -Msg "Is the data correct, YES to save, NO to edit again?" -ForegroundColor Green))
                    {
                        Write-Host ("Saving Changes...") -ForegroundColor Yellow -NoNewline
                        $jsonContent = $jsonObject | ConvertTo-Json
                        $jsonContent | Set-Content -Path $softPathInfo
                        Write-Host (" [√]") -ForegroundColor Green
                        break;
                    }

                } while ($true)
                
                $dataReturn  = $true
            }
            catch
            {
                $dataReturn  = $false
                $errCode     = $_.Exception.HResult
                $errMsg      = $_.Exception.Message
                $errLocation = $_.InvocationInfo.PositionMessage
                Write-Host ("Code Error '{0}' - Error: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red
            }
        }
        Write-Host ""
        return $dataReturn
    }

    [hashtable] ReadFileInfoSoftwarePubic([string] $software, [string] $version, [bool] $forzeEdit) {
        <#
        .SYNOPSIS
            Lee la configuración del software desde un archivo JSON.

        .DESCRIPTION
            Esta función lee la configuración del software desde un archivo JSON especificado y devuelve un
            hashtable que contiene las propiedades del software.

        .PARAMETER $software
            El nombre del software.

        .PARAMETER $version
            La versión del software.

        .PARAMETER $forzeEdit
            Un indicador booleano que indica si se debe forzar la edición del archivo de configuración JSON.

        .OUTPUTS
            [hashtable] Un hashtable que contiene las propiedades del software, incluidos los reemplazos y las
            configuraciones del software.

        #>
        $dataReturn = @{
            "Options"   = @{}
            "Remplaces" = @{}
            "Win32App"  = @{}
            "MSI"       = @{}
            "status"    = $false
            "error"     = @{
                "code"     = 0
                "msg"      = ""
                "location" = ""
            }
        }

        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            $errMsg = "ReadFileInfoSoftwarePubic: Missing data - Software ({0}), Version ({1})!!" -f $software, $version
            Write-Host $errMsg -ForegroundColor Red
            Write-Host ""

            $dataReturn["error"]['msg']  = $errMsg
            $dataReturn["error"]['code'] = "1"
        }
        else
        {
            $queryEditAppInfo = $false
            $newInfoJSON      = $false

            if ($this.IsExistFileInfoSoftwarePublish($software, $version) -eq $true)
            {
                $softPathInfo = $this.GetPathFileInfoSoftwarePublish($software, $version)
            }
            else
            {
                $softPathInfo = $this.GetPathFileInfoSoftwarePublish($software, "")
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
                    $Win32AppOptions   = @{}
                    $Win32AppMSI       = @{}


                    # Cargamos la configuracion de info.json para ver si tenemos que editarla
                    $jsonContent = Get-Content -Path $softPathInfo | Out-String
                    $jsonObject = $jsonContent | ConvertFrom-Json

                    if ($newInfoJSON -eq $false -and $forzeEdit -eq $false)
                    {
                        Clear-Host
                        Write-Host "Current Data:" -ForegroundColor Yellow
                        Write-Host (Write-Output $jsonObject.Win32App | Format-List | Out-String)

                        $queryEditAppInfo = QueryYesNo -Msg "Do you want to edit the data?" -ForegroundColor Green
                        Write-Host ""
                    }
                    
                    if ($queryEditAppInfo -eq $true -or $newInfoJSON -eq $true -or $forzeEdit -eq $true)
                    {
                        $this.EditFileInfoSoftwarePublish($softPathInfo)
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
                    if ($infoJsonContent.PSObject.Properties.Name -contains "Options")
                    {
                        $Win32AppOptions = $infoJsonContent.Options
                    }
                    if ($infoJsonContent.PSObject.Properties.Name -contains "MSI")
                    {
                        $Win32AppMSI = $infoJsonContent.MSI
                    }
                    
                    $dataReturn = @{
                        "Options"   = $Win32AppOptions
                        "Remplaces" = $Win32AppRemplaces
                        "Win32App"  = $Win32AppArgs
                        "MSI"       = $Win32AppMSI
                        "status"    = $true
                    }
                }
                catch
                {
                    $errCode     = $_.Exception.HResult
                    $errMsg      = $_.Exception.Message
                    $errLocation = $_.InvocationInfo.PositionMessage
                    Write-Host ("Code Error '{0}' - Error: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red
                    Write-Host ""

                    $dataReturn["error"]["code"]     = $errCode
                    $dataReturn["error"]["msg"]      = $errMsg
                    $dataReturn["error"]["location"] = $errLocation
                }
            }
            else
            {
                $errMsg = ("File '{0}' not found. :(" -f $softPathInfo)
                Write-Host $errMsg -ForegroundColor Red
                Write-Host ""

                $dataReturn["error"]["code"] = 2
                $dataReturn["error"]["msg"]  = $errMsg
            }
        }
        return $dataReturn
    }




    [string] GetPathLogoSoftware([string] $software, [string] $version) {
        <#
        .SYNOPSIS
            Obtiene la ruta del archivo de logo para un software específico.

        .DESCRIPTION
            Esta función construye la ruta del archivo de logo para un software y su versión específicos. La ruta se construye
            utilizando la ruta raíz del software, el nombre del software y la versión. Si no se proporciona una versión, la 
            función devuelve la ruta al directorio de logos sin una versión específica.

        .PARAMETER $software
            El nombre del software.

        .PARAMETER $version
            La versión específica del software.

        .OUTPUTS
            [string] La ruta completa del archivo de logo, incluyendo el nombre del archivo.
        #>
        $path = $this.GetRootPathSoftware()
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }

        $path = Join-Path $path $software
        if (-not [string]::IsNullOrEmpty($version))
        {
            $path = Join-Path $path $this.PathSoftSource
            $path = Join-Path $path $version
        }
        
        $path = Join-Path $path $this.PathSoftLogo
        $path = Join-Path $path $this.NameFileLogo
        return $path
    }




    [string] GetPathScriptDetect([string] $software, [string] $version) {
        <#
        .SYNOPSIS
            Obtiene la ruta del script de detección para un software específico y su versión.

        .DESCRIPTION
            Esta función construye la ruta del script de detección para un software y su versión específicos. La ruta se construye utilizando la ruta raíz del software, el nombre del software, la versión y la estructura de carpetas estándar. Si no se proporciona una versión, la función devuelve la ruta al script de detección sin una versión específica.

        .PARAMETER $software
            El nombre del software.

        .PARAMETER $version
            La versión específica del software.

        .OUTPUTS
            [string] La ruta completa del script de detección, incluyendo el nombre del archivo.
        #>

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
        $path = Join-Path $path $this.PathSoftSource
        $path = Join-Path $path $version
        $path = Join-Path $path $this.PathSoftScript
        $path = Join-Path $path $this.NameFileDetect
        return $path
    }




    [bool] CheckIfPublishSoftware([string] $software, [string] $version) {
        <#
        .SYNOPSIS
            Verifica si un software específico y su versión están presentes en Intune.

        .DESCRIPTION
            Esta función comprueba si un software y su versión específica están presentes en Intune. Utiliza el
            nombre del software y la versión para buscar en Intune y determina si la aplicación está disponible.

        .PARAMETER $software
            El nombre del software.

        .PARAMETER $version
            La versión específica del software.

        .OUTPUTS
            [bool] True si el software y la versión están presentes en Intune, False de lo contrario.
        #>
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
            if ($Win32AppInfo -is [int])
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
            Write-Host ("CheckIfPublishSoftware: Unsupported Format Return '{0}' - Software '{1}', Version '{2}'!!" -f $formatoResult, $software, $version) -ForegroundColor Yellow
            Write-Host ""
            return $false
        }
    }




    [bool] PublishSoftware([string] $software, [string] $version, [string] $fileIntuneWin) {
        if ($this.GetIsEnabled() -eq $false)
        {
            Write-Host "Cannot publish, itunes support is disabled!" -ForegroundColor Yellow
            Write-Host ""
            return $false
        }

        $configRead = $this.ReadFileInfoSoftwarePubic($software, $version, $false)
        if ($configRead['status'] -eq $false)
        {
            Write-Host ("Aborted Process, error ({0}) : {1}" -f $configRead['error']['code'], $configRead['error']['msg']) -ForegroundColor Red
            Write-Host ""
            return $false
        }
        $Win32AppOptions   = $configRead['Options']
        $Win32AppArgs      = $configRead['Win32App']
        $Win32AppRemplaces = $configRead['Remplaces']
        $Win32AppMSI       = $configRead['MSI']




        # Revisa si falta algun dato requerid
        while ($this.CheckRequieredValues($Win32AppArgs) -eq $false) {

            # $msgQuery = $(Write-Host "(Y/N)" -ForegroundColor Yellow -NoNewline $(Write-Host "Is any of the required data missing, YES to edit the data, NO abort publication? " -ForegroundColor Green -NoNewLine))
            $queryEditAppInfoRequierdMissing = QueryYesNo -Msg "Is any of the required data missing, YES to edit the data, NO abort publication?" -ForegroundColor Green
            Write-Host ""
            if ($queryEditAppInfoRequierdMissing -eq $true)
            {
                $configRead = $this.ReadFileInfoSoftwarePubic($software, $version, $true)
                if ($configRead['status'] -eq $true)
                {
                    $Win32AppOptions   = $configRead['Options']
                    $Win32AppArgs      = $configRead['Win32App']
                    $Win32AppRemplaces = $configRead['Remplaces']
                    $Win32AppMSI       = $configRead['MSI']
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
                Write-Host ("Aborted Process!") -ForegroundColor Red
                Write-Host ""
                return $false
            }
        }




        $connect = $this.ConnectMSIntune($false)
        if ($connect -eq $false) {
            return $false
        }




        # Prepara los datos para subir la App a intune

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
            Write-Host ("IntuneWin File '{0}' not found!" -f $Win32AppArgs['FilePath']) -ForegroundColor Red
            Write-Host ""
            Start-Sleep -Seconds 2
            return $false
        }
        
        


        $isPublishSoftware = $this.CheckIfPublishSoftware($software, $Win32AppArgs['AppVersion'])
        if ($null -eq $isPublishSoftware)
        {
            return $false
        }
        elseif ($isPublishSoftware -eq $true)
        {
            $Win32AppInfo = Get-IntuneWin32App -DisplayName $software | Where-Object { $_.displayVersion -eq $Win32AppArgs['AppVersion'] }

            if ($Win32AppInfo.PSObject.Properties.Match('Count').Count -gt 0)
            {
                Write-Host ("This version of the app has been found repeated {0} times. Take a look!" -f $Win32AppInfo.Count) -ForegroundColor Red
                Write-Host ""
                Get-IntuneWin32App -DisplayName $software | Where-Object { $_.displayVersion -eq $Win32AppArgs['AppVersion'] } | Select-Object -Property displayName, displayVersion, id, createdDateTime | Sort-Object -Property createdDateTime
            }
            elseif ($Win32AppInfo.PSObject.Properties.Match('id').Count -gt 0)
            {
                Write-Host ("Updating PackageFile App [{0} {1}]..." -f $software, $Win32AppArgs['AppVersion']) -ForegroundColor Green
                Update-IntuneWin32AppPackageFile -ID $Win32AppInfo.id -FilePath $Win32AppArgs['FilePath']
                Write-Host ("Complete Update!") -ForegroundColor Green
                Write-Host ""
                Start-Sleep -Seconds 2
                return $true
            }
            else
            {
                Write-Host ("Updating PackageFile aborted, no ID detected!") -ForegroundColor Red
            }
            Write-Host ""
            Start-Sleep -Seconds 2
            return $false
        }
        else
        {
            # Check Script Detecction
            Write-Host ("Searching Script Detection...") -ForegroundColor Yellow -NoNewLine
            $softVerScriptDetection = $this.GetPathScriptDetect($software, $Win32AppArgs['AppVersion'])
            if ([string]::IsNullOrEmpty($softVerScriptDetection) -or -not (Test-Path -Path $softVerScriptDetection -PathType Leaf))
            {
                Write-Host (" [X]") -ForegroundColor Red
                Write-Host ("Aborted Process, Detection Script '{0}' not found!" -f $softVerScriptDetection) -ForegroundColor Red
                Write-Host ""
                Start-Sleep -Seconds 2
                return $false
            }
            Write-Host (" [√]") -ForegroundColor Green



            # Create Logo
            Write-Host ("Searching Logo...") -ForegroundColor Yellow -NoNewLine
            $softFileLogo = $this.GetPathLogoSoftware($software, $Win32AppArgs['AppVersion'])
            if ([string]::IsNullOrEmpty($softFileLogo) -or -not (Test-Path -Path $softFileLogo -PathType Leaf))
            {
                $softFileLogo = $this.GetPathLogoSoftware($software, "")
            }
            if ([string]::IsNullOrEmpty($softFileLogo) -or -not (Test-Path -Path $softFileLogo -PathType Leaf))
            {
                $softFileLogo = $null
                Write-Host (" [X]") -ForegroundColor Red
                Write-Host ("Skip, no Logo Detected!") -ForegroundColor Yellow
                Write-Host ""
            }
            else
            {
                $Win32AppArgs['Icon'] = New-IntuneWin32AppIcon -FilePath $softFileLogo
                Write-Host (" [√]") -ForegroundColor Green
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



            Write-Host ("Publishing App [{0} {1}]..." -f $Win32AppArgs['DisplayName'], $Win32AppArgs['AppVersion']) -ForegroundColor Green
            Add-IntuneWin32App @Win32AppArgs
            Write-Host ("Publishing Completed!") -ForegroundColor Green
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
    }











    [String] GetCurrentSO(){
        <#
        .SYNOPSIS
            Devuelve el nombre del sistema operativo actual si se encuentra en una lista predefinida de sistemas operativos compatibles, incluyendo
            Windows, macOS (OSX), Linux y FreeBSD.

        .DESCRIPTION
            El método GetCurrentSO verifica el sistema operativo actual utilizando la clase [System.Runtime.InteropServices.RuntimeInformation] y
            compara el nombre del sistema operativo con una lista de sistemas operativos compatibles. Si el sistema operativo actual se encuentra
            en la lista, devuelve el nombre del sistema operativo; de lo contrario, devuelve $null.

        .OUTPUTS
            [String] El método devuelve el nombre del sistema operativo actual si se encuentra en la lista de sistemas operativos compatibles. Si 
            el sistema operativo actual no está en la lista, devuelve $null.
        #>
        $validOS    = @('Windows', "OSX", "Linux", "FreeBSD")
        $dataReturn = $null
        foreach ($nameOS in $validOS) {
            if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::$nameOS))
            {
                $dataReturn = $nameOS
                break
            }
        }
        return $dataReturn
    }

    [bool] GetIsSupportSO([string[]] $supportedOSs, [bool]$showMsg) {
       <#
        .SYNOPSIS
            Verifica si el sistema operativo actual está entre los sistemas operativos soportados definidos en una lista.

        .DESCRIPTION
            El método GetIsSupportSO compara el tipo de sistema operativo actual con los sistemas operativos soportados especificados
            en el array $supportedOSs. Si el sistema operativo actual está en la lista de sistemas operativos soportados, devuelve $true;
            de lo contrario, devuelve $false. Si $showMsg es verdadero y el sistema operativo no está soportado, muestra un mensaje de
            advertencia.

        .PARAMETER supportedOSs
            Un array de cadenas que representa los sistemas operativos soportados. Puede contener valores como "Windows", "Linux", "OSX", o "all"
            para indicar todos los sistemas operativos.

        .PARAMETER showMsg
            Un valor booleano que indica si se debe mostrar un mensaje de advertencia si el sistema operativo actual no está soportado. Si es 
            $true, se mostrará el mensaje; si es $false, no se mostrará ningún mensaje.

        .OUTPUTS
            [bool] El método devuelve $true si el sistema operativo actual está soportado, de lo contrario, devuelve $false.
        #>
        $currentOSType     = $this.OSType.ToLower()
        $supportedOSsLower = $supportedOSs | ForEach-Object { $_.ToLower() }

        $dataReturn = ($supportedOSsLower -contains "all" -or $supportedOSsLower -contains $currentOSType)
        if ($dataReturn -eq $false -and $showMsg)
        {
            Write-Host ("Current System '{0}', This System Is Not Supported Among the Defined Systems [{1}]!" -f $this.OSType,  ($supportedOSs -join ", ")) -ForegroundColor Yellow
        }
        return $dataReturn
    }




   


    [string] GetFileIntuneWinSetupFile([string] $SetupFile) {
        <#
        .SYNOPSIS
            Genera el nombre del archivo de configuración para un paquete IntuneWin.

        .DESCRIPTION
            El método GetFileIntuneWinSetupFile toma el nombre del archivo de configuración original (almacenado en $SetupFile) y 
            genera un nuevo nombre de archivo con la extensión ".intunewin". Si el nombre del archivo de configuración está vacío
            o nulo, el método devuelve una cadena vacía ("").

        .PARAMETER $SetupFile
            Nombre del archivo de configuración original.

        .OUTPUTS
            [String] El método devuelve una cadena que representa el nombre del archivo de configuración para el paquete IntuneWin,
            con la extensión ".intunewin" añadida al nombre del archivo original.
        #>
        if ([string]::IsNullOrEmpty($SetupFile))
        {
            return $null
        }
        return "{0}.intunewin" -f [System.IO.Path]::GetFileNameWithoutExtension($SetupFile)
    }

    [string] GetPahtOutFileIntuneWinSetupFile([string] $software, [string] $SetupFile)
    {
        <#
        .SYNOPSIS
            Este método devuelve la ruta de salida completa para un archivo de configuración de paquete IntuneWin, utilizando el nombre
            del software y el nombre del archivo de configuración original como entrada.

        .DESCRIPTION
            El método GetPahtOutFileIntuneWinSetupFile toma el nombre del software y el nombre del archivo de configuración original
            (almacenado en $SetupFile) para construir la ruta de salida completa para un archivo de configuración de paquete IntuneWin.
            Utiliza los métodos GetOutPath y GetFileIntuneWinSetupFile para obtener la ruta de salida y el nombre del archivo de 
            configuración respectivamente.

        .PARAMETER $software
            Nombre del software para el cual se está generando el paquete IntuneWin.

        .PARAMETER $SetupFile
            Nombre del archivo de configuración original.

        .OUTPUTS
            [String] El método devuelve una cadena que representa la ruta de salida completa para el archivo de configuración del paquete
            IntuneWin. Si no se puede generar returna $null.
        #>
        if ([string]::IsNullOrEmpty($SetupFile) -or [string]::IsNullOrEmpty($software))
        {
            return $null
        }

        $path           = $this.GetOutPath($software)
        $OutputFileName = $this.GetFileIntuneWinSetupFile($SetupFile)
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($OutputFileName))
        {
            return $null
        }

        $path = Join-Path $path $OutputFileName
        return $path
    }


    [string] GetFileIntuneWinSoftware([string] $software, [string] $version) {

          if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            return $null
        }
        return ("{0}_{1}.intunewin" -f $software, $version)
    }

    [string] GetPathOutFileIntuneWinSoftware([string] $software, [string] $version)
    {
        <#
        .SYNOPSIS
            Este método devuelve la ruta de salida completa para un archivo de paquete IntuneWin, utilizando
            el nombre del software y la versión como entrada.

        .DESCRIPTION
            El método GetPathOutFileIntuneWinSoftware toma el nombre del software y la versión como parámetros de
            entrada y construye la ruta de salida completa para un archivo de paquete IntuneWin. Utiliza el método
            GetOutPath para obtener la ruta de salida base y luego concatena el nombre del software, la versión y 
            la extensión ".intunewin" para generar el nombre del archivo.

        .PARAMETER $software
            Nombre del software para el cual se está generando el paquete IntuneWin.

        .PARAMETER $version
            Versión del software para la cual se está generando el paquete IntuneWin.

        .OUTPUTS
            [String] El método devuelve una cadena que representa la ruta de salida completa para el archivo de
            paquete IntuneWin. Si no se puede generar returna $null.
        #>
        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version))
        {
            return $null
        }

        $path     = $this.GetOutPath($software)
        $filename = $this.GetFileIntuneWinSoftware($software, $version)
        if ([string]::IsNullOrEmpty($path) -or [string]::IsNullOrEmpty($filename))
        {
            return $null
        }
        $path = Join-Path $path $filename
        return $path
    }
    


    [bool] RenameIntuneWinSetupFile([string] $software, [string] $version, [string] $setupFile, [bool] $force)
    {
        if ([string]::IsNullOrEmpty($software) -or [string]::IsNullOrEmpty($version) -or [string]::IsNullOrEmpty($setupFile))
        {
            return $false
        }
        $pathSetupFile = $this.GetPahtOutFileIntuneWinSetupFile($software, $setupFile)
        $pathSoftware  = $this.GetPathOutFileIntuneWinSoftware($software, $version)

        if (-not $force -and (Test-Path -Path $pathSoftware -PathType Leaf))
        {
            return $false
        }

        Try
        {
            if (Test-Path -Path $pathSoftware -PathType Leaf)
            {
                Write-Host "Removing Old Version..." -ForegroundColor Green -NoNewLine
                Remove-Item -Path $pathSoftware -Force
                Write-Host (" [√]") -ForegroundColor Green
            }
            Write-Host "Renaming IntuneWin File..." -ForegroundColor Green -NoNewLine
            Rename-Item -Path $pathSetupFile -NewName $pathSoftware
            Write-Host (" [√]") -ForegroundColor Green
        }
        catch
        {
            Write-Host (" [X]") -ForegroundColor Red
            Write-Host ("Error RenameIntuneWin: {0}" -f $_) -ForegroundColor Red
            Write-Host ""
            return $false
        }
        return $true
    }





    [hashtable] CreateIntuneWin32AppPackage([string] $SourceFolder, [string] $SetupFile, [string] $OutputFolder, [bool] $force, [string] $IntuneWinAppUtilPath) {
        <#
        .SYNOPSIS
            Este método crea un paquete IntuneWin a partir de una carpeta de origen, un archivo de configuración y una carpeta de destino.
            Puede sobrescribir el archivo de salida si se proporciona el parámetro `-Force`.

        .DESCRIPTION
            El método CreateIntuneWin32AppPackage valida los datos proporcionados y, si son correctos, crea un paquete IntuneWin utilizando 
            la función New-IntuneWin32AppPackage. Verifica la existencia de la carpeta de origen, del archivo de configuración y de la carpeta
            de destino. Si alguna de estas condiciones no se cumple, muestra mensajes de error. Si el paquete IntuneWin se crea correctamente, 
            devuelve un hash con el estado de la operación y detalles adicionales.

        .PARAMETER $SourceFolder
            Ruta de la carpeta de origen que contiene los archivos para el paquete IntuneWin.

        .PARAMETER $SetupFile
            Nombre del archivo de configuración dentro de la carpeta de origen.

        .PARAMETER $OutputFolder
            Ruta de la carpeta de destino donde se guardará el paquete IntuneWin.

        .PARAMETER $force
            Indica si se debe sobrescribir el archivo de salida si ya existe.

        .OUTPUTS
            [System.Collections.Hashtable]
            Devuelve un hash con las siguientes claves:
            - 'Status'      : Indica si el proceso fue exitoso (true) o no (false).
            - 'OutputFile'  : Ruta del archivo de salida creado.
            - 'ErrorMsg'    : Mensaje de error, si hay algún problema durante el proceso.
            - 'ErrorMsgType': Tipo de mensaje de error (warning, error, etc.).
        #>
        $errMsgType = ""
        $errMsg     = ""
        $processOk  = $false
        $OutputFile = $null
        $Win32AppPackage = $null

        if (-not $this.GetIsSupportSO(@("Windows"), $true))
        {
            $errMsgType = "warning"
            $errMsg     = "Current OS '{0}' Is Not Supported!" -f $this.OSType
        }
        else
        {
            # Comprobamos los datos si son correctos

            $errMsg             = ""
            $errMsgType         = "warning"
            $errMsgColor        = "Yellow"
            
            $SetupFileFullPath  = $null
            $OutputFileName     = $null
            $OutputFileFullPath = $null

            if (-not [string]::IsNullOrEmpty($SourceFolder) -and -not [string]::IsNullOrEmpty($SetupFile) )
            {
                $SetupFile = $this.GetValidSetupFile($SourceFolder, $SetupFile, @(".exe", ".com", ".bat", ".cmd", ".ps1"))
                if (-not [string]::IsNullOrEmpty($SetupFile) )
                {
                    $SetupFileFullPath = Join-Path -Path $SourceFolder -ChildPath $SetupFile
                }
            }
            if (-not [string]::IsNullOrEmpty($SourceFolder) -and -not [string]::IsNullOrEmpty($SetupFile) )
            {
                $OutputFileName     = $this.GetFileIntuneWinSetupFile($SetupFile)
                $OutputFileFullPath = Join-Path -Path $OutputFolder -ChildPath $OutputFileName
            }

            if ([string]::IsNullOrEmpty($SourceFolder))
            {
                $errMsg = ("Source Folder '{0}' Is Not Defined!" -f $SourceFolder)
            }
            elseif (-not (Test-Path -Path $SourceFolder -PathType Container))
            {
                $errMsg = ("Source Folder '{0}' Is Not Exist!" -f $SourceFolder)
            }
            elseif ([string]::IsNullOrEmpty($SetupFile))
            {
                $errMsg = ("Setup File '{0}' Is Not Defined!" -f $SetupFile)
            }
            elseif (-not (Test-Path -Path $SetupFileFullPath -PathType Leaf))
            {
                $errMsg = ("Setup File '{0}' Is Not Exist!" -f $SetupFile)
            }
            elseif ([string]::IsNullOrEmpty($OutputFolder))
            {
                $errMsg = ("Output Folder '{0}' Is Not Defined!" -f $SourceFolder)
            }
            elseif (-not (Test-Path -Path $OutputFolder -PathType Container))
            {
                Write-Host "Output Folder Not Exist, Creating..." -NoNewLine -ForegroundColor Green
                try
                {
                    New-Item -Path $OutputFolder -ItemType Directory -Force
                    Write-Host (" [√]") -ForegroundColor Green

                    $processOk  = $true
                    $OutputFile = $OutputFileFullPath
                }
                catch
                {
                    Write-Host (" [X]") -ForegroundColor Red

                    $processOk   = $false
                    $errMsgType  = "error"
                    $errMsgColor = "Red"
                    $errMsg      = ("Error Creating Directory: {0}" -f $_)
                }
            }
            elseif ([string]::IsNullOrEmpty($OutputFileFullPath))
            {
                $errMsg = ("Output File Is Not Defined!")
            }
            elseif ($force -eq $false -and (Test-Path -Path $OutputFileFullPath -PathType Leaf))
            {
                $errMsg = ("Output File '{0}' Already Exists, Cannot be Overwritten Without Force!" -f $OutputFileName)
            }
            else
            {
                $processOk = $true
            }

            if ($processOk -eq $false) {
                Write-Host $errMsg -ForegroundColor $errMsgColor
                Write-Host ""
            }
        }

        if ($processOk)
        {
            Write-Host "Creating intunewin..." -NoNewLine -ForegroundColor Green
            try{
                if ($force)
                {
                    $Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -IntuneWinAppUtilPath $IntuneWinAppUtilPath -Force
                }
                else {
                    $Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $SourceFolder -SetupFile $SetupFile -OutputFolder $OutputFolder -IntuneWinAppUtilPath $IntuneWinAppUtilPath
                }
                Write-Host (" [√]") -ForegroundColor Green
                $processOk = $true
            }
            catch
            {
                Write-Host (" [X]") -ForegroundColor Red

                $errCode     = $_.Exception.HResult
                $errMsg      = $_.Exception.Message
                $errLocation = $_.InvocationInfo.PositionMessage

                $processOk   = $false
                $errMsgType  = "error"
                $errMsg      = ("Error Creating Intunewin ({0}): {1}" -f $errCode, $errMsg)

                Write-Host $errMsg -ForegroundColor Red
                Write-Host $errLocation -ForegroundColor Red
            }
            
        }
        return @{
            'Status'          = $processOk
            'OutputFile'      = $OutputFile
            'Win32AppPackage' = $Win32AppPackage
            'ErrorMsg'        = $errMsg
            'ErrorMsgType'    = $errMsgType
        }
    }
    
    [string] GetValidSetupFile ([string] $SourceFolder, [string]$SetupFile, [string[]]$validExtensions) {
        
        if ([string]::IsNullOrEmpty($SourceFolder))
        {
            return $null
        }

        $isChange = $false
        if ($null -eq $validExtensions -or $validExtensions.Count -eq 0) {
            $validExtensions = @("*")
        }
        $extList = $validExtensions -join ", "

        $SetupFileUndo     = $SetupFile
        $SetupFileFullPath = Join-Path $SourceFolder $SetupFile

        do {
            if (!(Test-Path -Path $SetupFileFullPath -PathType Leaf))
            {
                $isChange = $true
                # Clear-Host
                Write-Host "**********************************" -ForegroundColor Yellow
                Write-Host "****  Script/Program Install  ****" -ForegroundColor Yellow
                Write-Host "**********************************" -ForegroundColor Yellow
                Write-Host ""
                Write-Host ("File '{0}' is not found!" -f $SetupFile ) -ForegroundColor Red
                Write-Host ""

                $availableFiles = Get-ChildItem -Path $SourceFolder -File | Where-Object { $validExtensions -contains $_.Extension } | Select-Object -ExpandProperty Name
                if ($availableFiles.Count -gt 0)
                {
                    Write-Host "Available Files:"
                    foreach ($file in $availableFiles) {
                        Write-Host "  $file" -ForegroundColor Cyan
                    }
                }
                else
                {
                    Write-Warning ("There Are No Files With Valid Extensions: {0}" -f $extList)
                }
                Write-Host ""

                # $SetupFile = Read-Host "enter the name of the installation file (use !! to abort)"
                $SetupFile = $(Write-Host ("Enter The Name Of The Installation File (Use !! to Abort) ") -ForegroundColor Yellow -NoNewLine; Read-Host)

                #NOTA1: Aunque en el mensaje pone !!, powerhsell solo detecta !, si pones !! en el if no funciona.
                #NOTA2: La nota1 solo se aplica a PowerShell 5.1, en la version 7.3 el !! se detecta correctamente.
                if ($SetupFile -eq "!" -or $SetupFile -eq "!!")
                {
                    Write-Warning "Aborted Process!"
                    Write-Host ""
                    return $null
                }
                if ([string]::IsNullOrEmpty($SetupFile))
                {
                    Write-Warning "Can't Be Left Blank!"
                    $SetupFile = $SetupFileUndo
                    Start-Sleep -Seconds 2
                    Continue
                }
                $SetupFileUndo = $SetupFile
                Write-Host ""
                
                $SetupFileFullPath = Join-Path $SourceFolder $SetupFile
            }
        } while (!(Test-Path -Path $SetupFileFullPath -PathType Leaf))

        if ($isChange) {
            Write-Host ("New Installer: {0}" -f $SetupFile) -ForegroundColor Green
            Write-Host ""
        }
        return $SetupFile
    }
}
if (($null -eq $function:CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    Exit 1
}

class fileInfoJSON {

    [bool]$showMsg         = $true
    [string]$fileJSON      = ""
    [string[]]$optionsProp = @("label", "allowedValues", "defaultValue", "required")

    [ScriptBlock]$callback_SetDefault = $null;
    [ScriptBlock]$callback_ReadConfig = $null;
    [ScriptBlock]$callback_EditConfig = $null;

    
    fileInfoJSON() {
        $this.setFile("")
    }
    

    [void] SetFile([string] $file) {
        $this.fileJSON = $file
    }
    [string] GetFile () {
        return $this.fileJSON
    }
    [bool] IsExistFile() {
        $file = $this.GetFile()
        if ($this.IsSetFile() -and (Test-Path -Path $file -PathType Leaf))
        {
            return $true
        }
        return $false
    }
    [bool] IsSetFile() {
        $file = $this.GetFile()
        if ([string]::IsNullOrEmpty($file))
        {
            return $false
        }
        return $true
    }


    [bool] SetDefault([hashtable] $default, [hashtable] $props ,[string] $software, [bool] $force) {
        $dataReturn = $false

        $file = $this.GetFile()
        if ($this.IsSetFile() -eq $false)
        {
            if ($this.showMsg)
            {
                Write-Host ("SetDefault: File is null!") -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
        elseif ($this.IsExistFile() -eq $true -and $force -eq $false)
        {
            if ($this.showMsg)
            {
                Write-Host ("SetDefault: File ({0}) exist, Skip" -f $file) -ForegroundColor Yellow
                Start-Sleep -Seconds 1
            }
            $dataReturn = $true
        }
        else
        {
            if ($this.showMsg)
            {
                if ($this.IsExistFile())
                {
                    Write-Host ("Overwrite File '{0}', updating..." -f $file) -ForegroundColor Yellow -NoNewLine
                }
                else
                {
                    Write-Host ("File '{0}' does not exist, creating..." -f $file) -ForegroundColor Yellow -NoNewLine
                }
            }
            
            $jsonDefault = $default
            if ($null -ne $this.callback_SetDefault)
            {
                $this.callback_SetDefault.Invoke($this, $jsonDefault, $props, $software)
            }
            Write-Host (" [√]") -ForegroundColor Green

            $this.SaveConfig($jsonDefault)
            $dataReturn = $true
            
            if ($this.showMsg)
            {
                Start-Sleep -Seconds 2
                Write-Host ""
            }
        }
        return $dataReturn
    }



    [bool] SaveConfig([hashtable] $config) {

        if ($this.IsSetFile() -eq $false)
        {
            if ($this.showMsg)
            {
                Write-Host "Error: File not Set!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
            return $false
        }
        else
        {
            Try
            {
                if ($this.showMsg)
                {
                    Write-Host ("Saving...") -ForegroundColor Yellow -NoNewline
                }

                $file = $this.GetFile()
                $jsonString = $config | ConvertTo-Json
                $jsonString | Set-Content -Path $file

                if ($this.showMsg)
                {
                    Write-Host (" [√]") -ForegroundColor Green
                }
            }
            catch
            {
                $errCode     = $_.Exception.HResult
                $errMsg      = $_.Exception.Message
                $errLocation = $_.InvocationInfo.PositionMessage
                if ($this.showMsg)
                {
                    Write-Host (" [X]") -ForegroundColor Red
                }
                Write-Host ("Error '{0}' - Msg: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red
                Start-Sleep -Seconds 2
                return $false
            }
        }
        return $true
    }

    [hashtable] ReadConfig(){
        $dataReturn = @{
            "data"   = @{}
            "isNew"  = $false
            "status" = $false
            "error"  = @{
                "code"     = 0
                "msg"      = ""
                "location" = ""
            }
        }
        $file = $this.GetFile()

        if ($this.IsExistFile() -eq $false)
        {
            if ($this.SetDefault($false))
            {
                $dataReturn["isNew"] = $true
            }
            else
            {
                $dataReturn["error"]['msg']  = "Error Set Default in file '{0}'!" -f $file
                $dataReturn["error"]['code'] = 1
            }
        }

        if ($this.IsExistFile())
        {
            try
            {
                $infoJsonContent = Get-Content -Raw -Path $file | ConvertFrom-Json

                $dataReturn["data"] = $infoJsonContent
                if ($null -ne $this.callback_ReadConfig)
                {
                    $dataReturn["data"] = $this.callback_ReadConfig.Invoke($this, $infoJsonContent)
                }
                $dataReturn["status"] = $true
            }
            catch
            {
                $errCode     = $_.Exception.HResult
                $errMsg      = $_.Exception.Message
                $errLocation = $_.InvocationInfo.PositionMessage
                Write-Host ("Error '{0}' - Error: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red

                $dataReturn["error"]["code"]     = $errCode
                $dataReturn["error"]["msg"]      = $errMsg
                $dataReturn["error"]["location"] = $errLocation

                Start-Sleep -Seconds 2
            }
        }
        else
        {
            $errMsg = ("File '{0}' not found. :(" -f $file)
            if ($this.showMsg)
            {
                Write-Host $errMsg -ForegroundColor Red
                Write-Host ""
                Start-Sleep -Seconds 2
            }
            $dataReturn["error"]["code"] = 2
            $dataReturn["error"]["msg"]  = $errMsg
        }
        return $dataReturn
    }

    [bool] EditConfig([hashtable] $config, [hashtable] $options) {
        
        $dataReturn = @{
            "config" = @{}
            "status" = $false
            "save"   = $false
            "error"  = @{
                "code"     = 0
                "msg"      = ""
                "location" = ""
            }
        }
        if ($this.IsExistFile())
        {
            try {
                do {
                    foreach ($propiedad in $options.Keys)
                    {
                        $label           = $propiedad
                        $value           = ""
                        $allowedValues   = $null
                        $defaultValue    = ""
                        $required        = $false
                        $availableValues = $null

                        foreach ($input_prop in $this.optionsProp)
                        {
                            if ($options[$propiedad].ContainsKey($input_prop))
                            {
                                $inupt_value = $options[$propiedad][$input_prop]

                                if ($inupt_value -is [ScriptBlock])
                                {
                                    if ($null -ne $inupt_value)
                                    {
                                        $inupt_value = $inupt_value.Invoke($this)
                                    }
                                }
                                Set-Variable -Name $input_prop -Value $inupt_value
                            }
                        }

                        if ($config.PSObject.Properties[$propiedad] )
                        {
                            $value = $($config.$propiedad)
                        }
                        else
                        {
                            # # Convertir Win32App en un objeto PSObject para permitir propiedades dinámicas
                            # $jsonObject.Win32App = New-Object PSObject -Property $jsonObject.Win32App

                            # Agregar la nueva propiedad al objeto
                            $config | Add-Member -MemberType NoteProperty -Name $propiedad -Value $defaultValue
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
                            
                            if ($null -ne $availableValues)
                            {
                                if (-not $this.GetIsEnabled())
                                {
                                    Write-Warning ("Connection to Intune Is Disabled, We Can't Get The Available Values, The Generic Ones Will Be Displayed!!")
                                }
                                Write-Host ("Available: {0}" -f ($availableValues -join ", ") ) -ForegroundColor Green
                            }

                            # Start - Hook
                            if ($null -ne $this.callback_EditConfig)
                            {
                                $this.callback_EditConfig.Invoke($this, $propiedad, $value, $defaultValue)
                            }
                            # End - Hook

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
                        
                        # Actualizar la propiedad en $config
                        $config.$propiedad = $value
                    }
                    $dataReturn['config'] = $config

                    Clear-Host
                    Write-Host "New Data:" -ForegroundColor Yellow
                    Write-Host (Write-Output $config | Format-List | Out-String)

                    # TODO: Añadir opcion cancelar que no guarda y sale, deja sin cambios
                    if ((QueryYesNo -Msg "Is the data correct, YES to save, NO to edit again?" -ForegroundColor Green))
                    {
                        $dataReturn['save'] = $true
                        break;
                    }

                } while ($true)
                $dataReturn['status'] = $true
            }
            catch
            {
                $errCode     = $_.Exception.HResult
                $errMsg      = $_.Exception.Message
                $errLocation = $_.InvocationInfo.PositionMessage
                Write-Host ("Error '{0}' - Msg: {1} {2}" -f $errCode, $errMsg, $errLocation) -ForegroundColor Red

                $dataReturn['status']            = $false
                $dataReturn['error']['code']     = $errCode
                $dataReturn['error']['msg']      = $errMsg
                $dataReturn['error']['location'] = $errLocation
            }
        }
        Write-Host ""
        return $dataReturn
    }


}
if (($null -eq $function:CheckHack) -or (-not (CheckHack)))
{
    $isLoad = $false
    $scriptName = $MyInvocation.MyCommand.Name
    Write-Host "Error load script ($scriptName)." -ForegroundColor Red
    Exit 1
}

Import-Module .\clsPathItem.ps1
Import-Module .\clsPathItemPool.ps1
Import-Module .\clsConfig.ps1
Import-Module .\clsFileDownloader.ps1
Import-Module .\clsFileDownloaderPool.ps1
Import-Module .\clsIntuneWinAppUtil.ps1


function GetAsterisksLine($text) {
    $lineLength = $text.Length + 12  # Longitud del texto + 8 asteriscos (4 en cada lado) + 4 espacios (2 en cada lado)
    return ("*" * $lineLength)
}

function RefreshMSIntune {
    if (Test-AccessToken -eq $false)
    {
        Connect-MSIntuneGraph -TenantID $Global:AccessTokenTenantID -Refresh
    }
}

function ConnectTenantMSIntune {
    param(
        [string]$TenantID = ""
    )
    #Pre-reqs = Install-Module MSGraph, IntuneWin32App, AzureAD, and PSIntuneAuth

    if ($TenantID -ne "")
    {
        Write-Host ("Conectando con el Tenant...") -ForegroundColor Green
        try
        {
            $IntuneConnectWarnings = @()
            Connect-MSIntuneGraph -TenantID $TenantID  -WarningAction SilentlyContinue -WarningVariable IntuneConnectWarnings
            if ($IntuneConnectWarnings.Count -gt 0)
            {
                foreach ($IntuneConnectWarning in $IntuneConnectWarnings)
                {
                    switch -Regex ($IntuneConnectWarning) {
                        ".*User canceled authentication.*" {
                            # An error occurred while attempting to retrieve or refresh access token. Error message: User canceled authentication.
                            Write-Host ("Error: Se canceló la autenticación durante la conexión a Microsoft Intune.") -ForegroundColor Red
                            Write-Host ""
                            return $false
                        }
                        ".*Error message:*" {
                            Write-Host ("Error: {0}" -f $IntuneConnectWarning) -ForegroundColor Red
                            Write-Host ""
                            return $false
                        }
                        default {
                            Write-Host ("Advertencia: {0}" -f $IntuneConnectWarning) -ForegroundColor Yellow
                            Continue
                        }
                    }
                }
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
            return $false
        }
        Start-Sleep -Seconds 2
    }
    return $true
}

function QueryYesNo {
    param(
        [string]$msg,
        [string]$optYes = "^(si|sí|s|yes|y)$",
        [string]$optNo  = "^(no|n)$"
    )
    do {
        $respuesta = Read-Host $msg
        switch -Regex ($respuesta.ToLower()) {
            $optYes {
                return $true
            }
            $optNo {
                return $false
            }
            default {
                Write-Host "Opcion no valida!" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
} 

function SelectItemList {
    param(
        [System.Collections.Generic.List[string]]$lNames,
        [string]$title,
        [string]$msgEmpty,
        [string]$msgSelect,
        [string]$msgSelectErr
    )

    $nCount = [int]$lNames.Count

    # Obtener el ancho máximo necesario para los números
    $maxWidth = [Math]::Max([Math]::Ceiling([Math]::Log10($nCount + 1)), 2)
    if (($maxWidth + 2 ) -lt 8) { $maxWidth = 8 }
    else                        { $maxWidth = $maxWidth + 2 }


    

    do {
        Clear-Host
        Write-Host (GetAsterisksLine $title) -ForegroundColor Yellow
        Write-Host ("****  {0}  ****" -f $title) -ForegroundColor Yellow
        Write-Host (GetAsterisksLine $title) -ForegroundColor Yellow
        Write-Host ""

        if ($nCount -eq 0) {
            Write-Host $msgEmpty -ForegroundColor Yellow
            Write-Host ""
            return $null
        }

        for ($i = 0; $i -lt $nCount; $i++) {
            $formattedNumber = "{0}." -f ($i + 1)
            Write-Host (" {0}{1} - {2}" -f $formattedNumber, [string]::Empty.PadRight($maxWidth - $formattedNumber.Count), $lNames[$i])
        }
        Write-Host ""

        # Obtener la selección del usuario
        [int]$selectedItemIndex = Read-Host ("{0} [1 - {1}] (0 para salir)" -f $msgSelect, $nCount)
        if ($selectedItemIndex -eq 0)
        {
            Write-Host "Proceso abortado." -ForegroundColor Yellow
            Write-Host ""
            return $null
        }
        if ($selectedItemIndex -lt 1 -or $selectedItemIndex -gt $nCount)
        {
            Write-Host "Opcion no valida!" -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    } while ($selectedItemIndex -lt 1 -or $selectedItemIndex -gt $nCount)

    $selectedItemStr = $lNames[$selectedItemIndex - 1]

    if ([string]::IsNullOrEmpty($selectedItemStr))
    {
        Write-Host $msgSelectErr -ForegroundColor Red
        return $null
    }
    return $selectedItemStr
}

function Get-ValidInstallCmd {
    param (
        [string]$softCmdInstall,
        [string]$softVerPath,
        [string[]]$validExtensions
    )

    if ($null -eq $validExtensions -or $validExtensions.Count -eq 0) {
        $validExtensions = @("*")
    }
    $extList = $validExtensions -join ", "

    $softVerPathFull = Join-Path $softVerPath $softCmdInstall
    do {
        if (!(Test-Path -Path $softVerPathFull -PathType Leaf))
        {
            Clear-Host
            Write-Host "***************************************" -ForegroundColor Yellow
            Write-Host "****  Script/Programa Instalacion  ****" -ForegroundColor Yellow
            Write-Host "***************************************" -ForegroundColor Yellow
            Write-Host ""
            Write-Host ("El archivo '{0}' no se encuentra!" -f $softCmdInstall ) -ForegroundColor Red
            Write-Host ""

            $availableFiles = Get-ChildItem -Path $softVerPath -File | Where-Object { $validExtensions -contains $_.Extension }
            if ($availableFiles.Count -gt 0)
            {
                Write-Host "Archivos disponibles:"
                foreach ($file in $availableFiles) {
                    Write-Host "  $file" -ForegroundColor Cyan
                }
            }
            else
            {
                Write-Host ("No hay archivos con extensiones validas: {0}" -f $extList) -ForegroundColor Yellow
            }
            Write-Host ""

            $softCmdInstall = Read-Host "Introduzca el nombre del instalador (usar !! para salir)"
            #NOTA: Aunque en el mensaje pone !!, powerhsell solo detecta !, si pones !! en el if no funciona.
            if ($softCmdInstall -eq "!")
            {
                Write-Host "Proceso abortado." -ForegroundColor Yellow
                Write-Host ""
                return $null
            }

            $softVerPathFull = Join-Path $softVerPath $softCmdInstall
        }
    } while (!(Test-Path -Path $softVerPathFull -PathType Leaf))
    return $softCmdInstall
}
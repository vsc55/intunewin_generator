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
Import-Module .\clsFileInfoJSON.ps1
Import-Module .\clsIntuneWin32AppCustom.ps1


function GetAsterisksLine {
    param(
        [string]$Text,
        [string]$Char = "*",
        [int]$RestCount = 0
    )

    $lineLength = $Text.Length + $RestCount  # Longitud del texto + 8 asteriscos (4 en cada lado) + 4 espacios (2 en cada lado)
    return ($char * $lineLength)
}

function QueryYesNo {
    param(
        [string]$Msg,
        [string]$OptionsYes              = "^(si|sí|s|yes|y)$",
        [string]$OptionsNo               = "^(no|n)$",
        [ConsoleColor]$ForegroundColor   = "White",
        [ConsoleColor]$ForegroundColorYN = "Yellow",
        [bool]$OptionNotFoundIsFalse     = $false
    )
    do {
        $respuesta = $(Write-Host $(Write-Host " (Y/N)" -ForegroundColor $ForegroundColorYN -NoNewline $(Write-Host $msg -ForegroundColor $ForegroundColor -NoNewLine)) -NoNewLine; Read-Host)
        switch -Regex ($respuesta.ToLower()) {
            $OptionsYes {
                return $true
            }
            $OptionsNo {
                return $false
            }
        }

        if ($OptionNotFoundIsFalse -eq $true)
        {
            return $false
        }
        Write-Host "Invalid Option!" -ForegroundColor Red
        Start-Sleep -Seconds 2
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
    if (($maxWidth + 2) -lt 6) { $maxWidth = 6 }
    else                       { $maxWidth = $maxWidth + 2 }


    do {
        Clear-Host
        Write-Host ("╔════════════════{0}════════════════╗" -f (GetAsterisksLine -Text $title -Char "═") ) -ForegroundColor Green
        Write-Host ("║             ┌──{0}──┐             ║" -f (GetAsterisksLine -Text $title -Char "─") ) -ForegroundColor Green
        Write-Host ("╟─────────────┤  {0}  ├─────────────╢" -f $title) -ForegroundColor Green
        Write-Host ("║             └──{0}──┘             ║" -f (GetAsterisksLine -Text $title -Char "─") ) -ForegroundColor Green
        Write-Host ("╚══╦═════════════{0}════════════════╝" -f (GetAsterisksLine -Text $title -Char "═") ) -ForegroundColor Green 
        Write-Host ("   ║") -ForegroundColor Green

        if ($nCount -eq 0) {
            Write-Host $msgEmpty -ForegroundColor Yellow  $(Write-Host ("   ╚════█ ") -ForegroundColor Green -NoNewline )
            # Write-Host $msgEmpty -ForegroundColor Yellow
            Write-Host ""
            return $null
        }

        Write-Host ("   █") -ForegroundColor Green
        for ($i = 0; $i -lt $nCount; $i++) {
            $formattedNumber = "{0}." -f ($i + 1)
            Write-Host ("   {0} ╾{1}╼ {2}" -f $formattedNumber, ("─" * ($maxWidth - $formattedNumber.Length)), $lNames[$i]) -ForegroundColor Green
        }
        Write-Host ""

        # Obtener la selección del usuario
        # [int]$selectedItemIndex = Read-Host ("{0} [1 - {1}] (0 Or Enter To Exit)" -f $msgSelect, $nCount)
        try {
            [int]$selectedItemIndex = $(Write-Host ("{0} [1 - {1}] (0 Or Enter To Exit) " -f $msgSelect, $nCount) -ForegroundColor Yellow -NoNewLine; Read-Host)
        }
        catch {
            $selectedItemIndex = -1
        }
        
        if ($selectedItemIndex -eq 0)
        {
            Write-Warning "Aborted Process!"
            Write-Host ""
            return $null
        }
        if ($selectedItemIndex -lt 1 -or $selectedItemIndex -gt $nCount)
        {
            Write-Host "Invalid Option!" -ForegroundColor Red
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

function Get-ValidarURL {
    param (
        [string]$url
    )

    # Expresión regular para validar una URL
    $patronURL = "^(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?$"
    $regex = New-Object System.Text.RegularExpressions.Regex $patronURL

    # Validar la URL
    if ($regex.IsMatch($url)) {
        return $true  # La URL está bien formada
    } else {
        return $false  # La URL no está bien formada
    }
}
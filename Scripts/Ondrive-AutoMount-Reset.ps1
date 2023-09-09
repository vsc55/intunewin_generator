$Path = "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
$Name = "Timerautomount"
$Type = "QWORD"
$Value = 1

Try {
    Write-Warning "Timer Automount Not configured to zero. Set to 0 Now"
    Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 

    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value)
    {
        Write-Output "Timer Automount Set to zero"
    } 
    else
    {
        Write-Warning "Timer Automount Not configured to zero. Set to 0 Now"
        Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 
    }
    Exit 0
} 
Catch {
    $errCode = $_.Exception.HResult
    $errMsg = $_.Exception.Message

    Write-Warning ("Another Issue Occured ({0}): {1}" -f $errCode, $errMsg)
    Exit 1
}
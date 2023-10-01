# Obtiene la ruta del directorio actual del script
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Obtén la lista de archivos MSI en el directorio del script
$msiFiles = Get-ChildItem -Path $scriptDirectory -Filter "*.msi" -File

# Crea una instancia del objeto WindowsInstaller
$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer

# Recorre cada archivo MSI y obtén su Product ID
foreach ($msiFile in $msiFiles) {
    $msiPath = $msiFile.FullName

    # Abre la base de datos MSI
    $msiDatabase = $WindowsInstaller.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $WindowsInstaller, @($msiPath, 0))

    # Consulta para obtener el Product ID
    $query = "SELECT Value FROM Property WHERE Property='ProductCode'"

    # Abre una vista en la base de datos
    $View = $msiDatabase.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $msiDatabase, ($query))

    # Ejecuta la consulta
    $View.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $View, $null)

    # Obtiene el registro de la vista
    $Record = $View.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $View, $null)

    # Obtiene el Product ID
    $ProductID = $Record.GetType().InvokeMember('StringData', 'GetProperty', $null, $Record, 1)

    # Muestra el Product ID junto con el nombre del archivo MSI
    Write-Host "Product ID: $ProductID - Archivo MSI: $($msiFile.Name)"
}
pause
$AppName           = "*HP Wolf*"
$InstalledPrograms = Get-Package | Where  { $_.Name -like $AppName }

# Remove installed programs
$InstalledPrograms | ForEach {
    Write-Host -Object "Attempting to uninstall: [$($_.Name)]..."
    Try {
        $Null = $_ | Uninstall-Package -AllVersions -Force -ErrorAction Stop
        Write-Host -Object "Successfully uninstalled: [$($_.Name)]"
    }
    Catch {Write-Warning -Message "Failed to uninstall: [$($_.Name)]"}
}
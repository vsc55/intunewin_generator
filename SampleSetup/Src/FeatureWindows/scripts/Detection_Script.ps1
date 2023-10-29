$FeatureName = "NetFx3" # Nombre de la caracteristica

$FeatureInfo = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $FeatureName }
if ($null -ne $FeatureInfo -and $FeatureInfo.State -eq 'Enabled')
{
    Write-Host "Installed"
    Exit 0
}
else
{
    Write-Host "No Installed"
    Exit 1
}
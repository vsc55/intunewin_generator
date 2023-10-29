$FeatureName = "NetFx3"

$dataFeature = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq $FeatureName }
if ($null -ne $dataFeature -and $dataFeature.State -eq 'Enabled')
{
    Write-Host ("Enabled {0}" -f $FeatureName)
    Exit 0
}
else
{
    Exit 1
}
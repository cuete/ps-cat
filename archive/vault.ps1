param ([Parameter(Mandatory=$true)][string]$vaultName)

Login-AzureRmAccount

Get-AzureKeyVaultSecret -Vaultname $vaultName | Select-Object Name | Out-Host
$secretName = Read-Host -Prompt 'Type name of the secret to fetch'
$secretVersion = Get-AzureKeyVaultSecret -Vaultname $vaultName -Name $secretName | Select-Object -ExpandProperty Version
$secretValue = Get-AzureKeyVaultSecret -Vaultname $vaultName -Name $secretName -Version $secretVersion | Select-Object -ExpandProperty SecretValueText 
Write-Host "`nValue: $secretValue"
Set-Clipboard -Value $secretValue
Write-Host "`nValue copied to clipboard!`n"

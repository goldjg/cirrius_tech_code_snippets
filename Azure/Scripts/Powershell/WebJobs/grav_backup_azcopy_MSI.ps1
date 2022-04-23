$KeyVaultName = "<vault name>" 
$KeyVaultSecretName = "<secret name / version >"

Write-Output "Getting MSI Access Token"
$TokenAuthURI = $Env:MSI_ENDPOINT + "?resource=https://vault.azure.net&api-version=2017-09-01"
$TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
$AccessToken = $TokenResponse.access_token

Write-Output "Getting Secret from KeyVault"
$Headers = @{ 'Authorization' = "Bearer $AccessToken" }
$QueryUrl = "https://$KeyVaultName.vault.azure.net/secrets/" + $KeyVaultSecretName + "?api-version=7.0"

$KeyResponse = Invoke-RestMethod -Method GET -Uri $QueryUrl -Headers $Headers
$Secret= $keyResponse.Value

$BackupAgeLimit = (Get-Date).AddDays(-7);
$BaseDir="D:\home";
$WWWroot="$BaseDir\site\wwwroot";
$BackupDir="$WWWroot\backup";

Set-Location $WWWroot;
Write-Output "Initiating Grav backup"
php bin/grav backup
Set-Location D:\devtools\AzCopy;

Write-Output "Copying backup to blob storage"
.\AzCopy.exe /Source:D:\home\site\wwwroot\backup\ /Dest:https://storageacct.blob.core.windows.net/container/ /Pattern:*.zip /DestKey:$Secret /XO /XN

Write-Output "Removing backup from web app local storage"
Get-ChildItem ("$BackupDir\*.zip") | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $BackupAgeLimit } | Remove-Item -Force;
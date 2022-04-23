using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write-Host to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

function GetSecret () {
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $SecretURI
    )

    $Headers = @{ 'Authorization' = "Bearer $AccessToken" }
    $QueryUrl = "$SecretURI" + "?api-version=7.0"
    
    $KeyResponse = Invoke-RestMethod -Method GET -Uri $QueryUrl -Headers $Headers
    $Secret= $keyResponse.Value
    Return $Secret
}

# Interact with query parameters or the body of the request.
$name = $Request.Query.AppName
if (-not $name) {
    $name = $Request.Body.AppName
}

if ($name) {
    $status = [HttpStatusCode]::OK;
    
    $invalid_request =$false;

    switch ($name) {
        "App1" { $zone_secreturl = "https://<vaultname>.vault.azure.net/secrets/<secretname>/<secretversion>" }
        "App2" { $zone_secreturl = "https://<vaultname>.vault.azure.net/secrets/<secretname>/<secretversion>" }
        "App3" { $zone_secreturl = "https://<vaultname>.vault.azure.net/secrets/<secretname>/<secretversion>" }
        Default {$invalid_request = $true}
    }
    
    If (-not $invalid_request) {
        Write-Host "Received a valid appname: $name";
  
        Write-Host "Gathering details for KeyVault";
        
        $authkeyurl="https://<vaultname>.vault.azure.net/secrets/<secretname>/<secretversion>";
        $authmailurl="https://<vaultname>.vault.azure.net/secrets/<secretname>/<secretversion>";

        Write-Host "Enabling TLS 1.2";
        [Net.ServicePointManager]::SecurityProtocol = "tls12";

        Write-Output "Getting MSI Access Token"
        $TokenAuthURI = $Env:MSI_ENDPOINT + "?resource=https://vault.azure.net&api-version=2017-09-01"
        $TokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $TokenAuthURI
        $AccessToken = $TokenResponse.access_token
        
        Write-Host "Retrieving Auth Key"
        $authkey=GetSecret($authkeyurl)
        $authmail=GetSecret($authmailurl)
        $zone_id=GetSecret($zone_secreturl)
        $headers = @{
            'X-Auth-Key' = "$authkey"
            'X-Auth-Email' = "$authmail"
            'Content-Type' = "application/json"
        }
    
        $apicmd = "purge_cache";
        $apibody = '{"purge_everything":true}';

        $uri="https://api.cloudflare.com/client/v4/zones/$zone_id/$apicmd";

        $cfout=Invoke-RestMethod -UserAgent "AzRebuild_CF_Cache 1.0" `
            -uri $uri `
            -Method POST -Headers $headers -Body $apibody;
    
        Write-Host "Cloudflare purge request status`r`n$cfout`r`n";
        If ($cfout.success -eq "true"){
            Write-Host "Downloading sitemap"
        
            switch ($name) {
                "App1" { $sitemap_domain = "https://App1.co.uk"; }
                "App2" { $sitemap_domain = "https://App2.com" }
                "App3" { $sitemap_domain = "https://App3.info" }
            }

            $xml=Invoke-RestMethod "$sitemap_domain/sitemap.xml" -UseBasicParsing;
            Write-Host "Parsing sitemap URLs for $sitemap_domain"
            $xml.urlset.url.loc|ForEach-Object {Write-Host "Touching $_ to recache"; `
                                        $out=invoke-webrequest $_ -UseBasicParsing -UserAgent "AzRecache";
                                        Write-Host "StatusCode:" $out.StatusCode; 
                                        Write-Host "StatusDescription:" $out.StatusDescription;
                                        Write-Host "`r`n";
                                    }
            }
            else {
            $Body="Unable to connect to Cloudflare, aborted run.";
            $status=[HttpStatusCode]::BadRequest
            }
        }
        else {
            $Body="Invalid Application";
            $status=[HttpStatusCode]::BadRequest
        }
} else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name on the query string or in the request body."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})
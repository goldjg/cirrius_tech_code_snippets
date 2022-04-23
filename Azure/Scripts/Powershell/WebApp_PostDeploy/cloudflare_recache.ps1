write-host "Enabling TLS 1.2";
[Net.ServicePointManager]::SecurityProtocol = "tls12";

write-host "Purging Cloudflare cache"
$headers = @{
    'X-Auth-Key' = "<auth key - best to retrieve from key vault!>"
    'X-Auth-Email' = "user@domain"
    'Content-Type' = "application/json"
}
$cfout=Invoke-RestMethod -UserAgent "AzRebuild_CF_Cache 1.0" -uri https://api.cloudflare.com/client/v4/zones/%zone_key%/purge_cache -Method POST -Headers $headers -Body '{"purge_everything":true}'

Write-host "Cloudflare purge request status`r`n$cfout`r`n"

write-host "Downloading sitemap"
$xml=Invoke-RestMethod https://domain.com/sitemap.xml -UseBasicParsing;
write-host "Parsing sitemap URLs"
$xml.urlset.url.loc|ForEach-Object {write-host "Touching $_ to recache"; `
                                    $out=invoke-webrequest $_ -UseBasicParsing -UserAgent "AzRecache";
                                    Write-Host "StatusCode:" $out.StatusCode; 
                                    Write-Host "StatusDescription:" $out.StatusDescription;
                                    Write-Host "`r`n";
                                }

write-host "FIN"
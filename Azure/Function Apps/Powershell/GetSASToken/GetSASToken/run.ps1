using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$StartTime = Get-Date
$EndTime = $startTime.AddHours(2.0)

If ($env:SAST.Length -gt 0) {
    $endt=($env:SAST).Split('&')[4].Split('=')[1] -replace '%3A',':'
    If ((([DateTime]$endt - (Get-Date)).TotalSeconds -gt 0) -and (([DateTime]$endt - (Get-Date)).TotalSeconds -gt 300)) {
            $GetNewToken = $false
            Write-Host "Valid Token Found"
    } else {
        $GetNewToken = $true
        Write-Host "Existing token expired or about to expire - generating new token"
    }
} else {
    $GetNewToken = $true
    Write-Host "No token found - generating new token"
}

If ($GetNewToken) {
    $rslt = Get-AzStorageAccount -Name "<acct_name>" -ResourceGroupName "<rg_name>" | New-AzStorageContainerSASToken  -Container "<container_name>" -Permission rl -StartTime $StartTime -ExpiryTime $EndTime
    [Environment]::SetEnvironmentVariable("SAST",$rslt.TrimStart("?"))
    Write-Host "New token generated - will expire in 2 hours"
    $status = [HttpStatusCode]::OK
    $body = $rslt
} else {
    $status = [HttpStatusCode]::OK
    $body = $env:SAST
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

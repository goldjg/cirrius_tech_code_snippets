using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.Name
$zone = $Request.Query.Zone
$reqIP = $Request.Query.reqIP
if (-not $name) {
    $name = $Request.Body.Name
}

if (-not $zone) {
    $zone = $Request.Body.Zone
}

if (-not $reqIP) {
    $reqIP = $Request.Body.reqIP
}

$sourceinfo=$Request.Headers['x-forwarded-for']
$sourceIP=$sourceinfo.split(",")[-1].Split(":")[0]

If ($name -and $zone) {
    #Check if name passed is already in DNS zone that was passed
    Try {$CurrentRec=Get-AzDnsRecordSet -Name $name -RecordType A -ZoneName $zone -ResourceGroupName MyDyner}
    Catch { write-host "Caught an exception:" -ForegroundColor Red
            write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
            write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red }
    If ($CurrentRec) {
        Write-Host "There is a current A record for $name in zone $zone"
        #Check current record IP against source/requested IP
        If (-not $reqIP) {
            Write-Host "No IP passed in request, checking source IP against current record"
            $CurrIP=$CurrentRec.Records.Ipv4Address
            If ($CurrIP -ne $sourceIP) {
                Write-Host "Source IP doesn't match current A record for $name in zone $zone : Updating with Source IP $sourceIP"
                $CurrentRec.Records[0].Ipv4Address = $sourceIP
                Set-AzDnsRecordSet -RecordSet $CurrentRec
                $body = "No IP passed - updated DNS record with source IP $sourceIP"
                $status = [HttpStatusCode]::OK
                Write-Host $body
            } else {
                $body = "Source IP and current DNS record match - no changes needed"
                $status = [HttpStatusCode]::OK
                Write-Host $body
            } 
        } else {
            Write-Host "IP Address $reqIP passed - updating DNS record accordingly"
            $CurrentRec.Records[0].Ipv4Address = $reqIP
            Set-AzDnsRecordSet -RecordSet $CurrentRec
            $body = "Updated DNS record with requested IP $reqIP"
            $status = [HttpStatusCode]::OK
            Write-Host $body
        }
    } else {
        Write-Host "No current A record for $name in zone $zone, adding now."
        If (-not $reqIP) {
        New-AzDnsRecordSet -Name $name -RecordType A -ZoneName $zone -ResourceGroupName MyDyner -Ttl 3600 -DnsRecords (New-AzDnsRecordConfig -Ipv4Address $sourceIP)
        $status = [HttpStatusCode]::OK
        $body = "No IP address requested - DNS Record created with source IP $sourceIP"
        Write-Host $body
        } else {
            New-AzDnsRecordSet -Name $name -RecordType A -ZoneName $zone -ResourceGroupName MyDyner -Ttl 3600 -DnsRecords (New-AzDnsRecordConfig -Ipv4Address $reqIP)
            $status = [HttpStatusCode]::OK
            $body = "DNS Record created with requested IP $reqIP"
            Write-Host $body
        }
    }      
} else {
    $status = [HttpStatusCode]::BadRequest
    $body = "Please pass a name and a zone on the query string or in the request body."
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
})

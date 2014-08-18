[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $WebServer = "192.168.100.1",
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $RetryCount = 10,
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    $RetryIntervalSec = 30
)

$isNotOnline = $true
$ctr = $null
while ($isNotOnline)
{
    write-verbose ("Loop count is at: {0} Is Not Online: {1}" -f $ctr,$isNotOnline)
    if ($ctr -lt $RetryCount)
        {
        if ((Test-Connection $WebServer -Count 1 -Quiet))
        {
            if ((Invoke-WebRequest -uri ("http://{0}" -f $WebServer) -ErrorAction SilentlyContinue).Statuscode -eq 200)
            {
                write-verbose ("Webservice on Server {0} online!" -f $WebServer)
                $isNotOnline = $false
                continue
            }
        }
    }
    else
    {
        break
    }
    Start-Sleep $RetryIntervalSec -Verbose
    $ctr += 1
}
#.\Check-Webservice.ps1 -RetryCount 5 -RetryIntervalSec 5 -WebServer "sadiist011"
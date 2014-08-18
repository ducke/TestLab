Configuration xDomJoin
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$MachineName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DomainFullName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$DomainAdminCred,
        $RetryCount,
        $RetryIntervalSec
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xActiveDirectory,xComputerManagement

    WindowsFeature RSATAD
    {
        Ensure = "Present"
        Name      = "RSAT-AD-Powershell"
    }

    xWaitForADDomain DscForestWait
    {
        DomainName = $DomainFullName
        DomainUserCredential = $DomainAdminCred
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
        DependsOn = "[WindowsFeature]RSATAD"
    }
    xComputer JoinDomain
    {
        Name = $MachineName
        DomainName = $DomainFullName
        Credential = $DomainAdminCred
        DependsOn = "[xWaitForADDomain]DscForestWait"
    }
}
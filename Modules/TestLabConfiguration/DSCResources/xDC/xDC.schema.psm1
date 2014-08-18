Configuration xDC
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $MachineName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$DomainFullName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PsCredential]$DomainAdminCred,
        [int]$RetryCount,
        [int]$RetryIntervalSec
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xActiveDirectory,xComputerManagement

    xComputer DCNewName
    {
            Name = $MachineName
    }

    WindowsFeature DCFeature2
    {
        Ensure = "Present"
        Name      = "AD-Domain-Services"
    }

    xWaitForADDomain DscForestWait
    {
        DomainName = $DomainFullName
        DomainUserCredential = $DomainAdminCred
        RetryCount = $RetryCount
        RetryIntervalSec = $RetryIntervalSec
        DependsOn = "[WindowsFeature]DCFeature2"
    }

    xADDomainController SecondDC
    {
        DomainName = $DomainFullName
        DomainAdministratorCredential = $DomainAdminCred
        SafemodeAdministratorPassword = $DomainAdminCred
        #DnsDelegationCredential = $DomainAdminCred
        DependsOn = "[xWaitForADDomain]DscForestWait"
    }
}
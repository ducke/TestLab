Configuration xPDC
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
        [PsCredential]$DomainAdminCred
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xActiveDirectory,xComputerManagement

    xComputer PDCNewName
    {
        Name = $MachineName
    }

    WindowsFeature PDCFeature
    {
        Ensure = "Present"
        Name      = "AD-Domain-Services"
    }

    xADDomain CreateForest
    {
        DomainName = $DomainFullName
        DomainAdministratorCredential = $DomainAdminCred
        SafemodeAdministratorPassword = $DomainAdminCred

        #DependsOn = "[WindowsFeature]DCFeature"
    }
}
Configuration xPullServer
{
    param
    (
        $ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules",
        $ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration"
    )

    # Import the module that defines custom resources
    Import-DSCResource -ModuleName xPSDesiredStateConfiguration

    WindowsFeature DSCServiceFeature
    {
        Ensure = "Present"
        Name   = "DSC-Service"
    }

    File EnsureModulePath {
            Type = 'Directory'
            DestinationPath = $ModulePath
            Ensure = "Present"
    }

    File EnsureConfigurationPath {
            Type = 'Directory'
            DestinationPath = $ConfigurationPath
            Ensure = "Present"
    }

    xDscWebService PSDSCPullServer
    {
        Ensure                  = "Present"
        EndpointName            = "PSDSCPullServer"
        Port                    = 8080
        PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCPullServer"
        CertificateThumbPrint   = "AllowUnencryptedTraffic"
        ModulePath              = $ModulePath
        ConfigurationPath       = $ConfigurationPath
        State                   = "Started"
        #DependsOn               = "[WindowsFeature]DSCServiceFeature"
    }

    xDscWebService PSDSCComplianceServer
    {
        Ensure                  = "Present"
        EndpointName            = "PSDSCComplianceServer"
        Port                    = 9080
        PhysicalPath            = "$env:SystemDrive\inetpub\wwwroot\PSDSCComplianceServer"
        CertificateThumbPrint   = "AllowUnencryptedTraffic"
        State                   = "Started"
        IsComplianceServer      = $true
        #DependsOn               = ("[WindowsFeature]DSCServiceFeature","[xDSCWebService]PSDSCPullServer")
    }
}
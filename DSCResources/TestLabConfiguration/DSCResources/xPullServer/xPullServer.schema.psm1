Configuration xPullServer
{
    param
    (
        $ModulePath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules",
        $ConfigurationPath = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration",
        $SourcePath = "$env:SystemDrive\Source"
    )

    Import-DSCResource -ModuleName xPSDesiredStateConfiguration,xSmbShare

    WindowsFeature DSCService
    {
        Ensure = "Present"
        Name   = "DSC-Service"
    }

    WindowsFeature WebMgmtTools
    {
        Ensure = "Present"
        Name   = "Web-Mgmt-Tools"
    }

    File EnsureModulePath
    {
            Type = 'Directory'
            DestinationPath = $ModulePath
            Ensure = "Present"
    }

    File EnsureConfigurationPath
    {
            Type = 'Directory'
            DestinationPath = $ConfigurationPath
            Ensure = "Present"
    }

    File EnsureSourcePath
    {
            Type = 'Directory'
            DestinationPath = $SourcePath
            Ensure = "Present"
    }

    xSmbShare SourceShare
    {
          Ensure = "Present"
          Name   = "SourceShare"
          Path = $SourcePath
          ReadAccess = "Everyone"
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
Configuration xKibana
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $KibanaSourcePath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $KibanaDestinationPath

    )
    Import-DSCResource -ModuleName xWebAdministration

    File EnsureKibanaSource
    {
            Type = 'Directory'
            SourcePath = "$KibanaSourcePath\kibana-3.1.0"
            DestinationPath = $KibanaDestinationPath
            Ensure = "Present"
            Recurse = $true
    }

    File EnsureKibanaConfigFile
    {
            Type = 'File'
            SourcePath = "$KibanaSourcePath\config.js"
            DestinationPath = "$KibanaDestinationPath\config.js"
    }

    # Install the IIS role
    WindowsFeature IIS
    {
        Ensure          = "Present"
        Name            = "Web-Server"
    }

    WindowsFeature WebMgmtTools
    {
        Ensure = "Present"
        Name   = "Web-Mgmt-Tools"
    }

    # Stop the default website
    xWebsite DefaultSite
    {
        Ensure          = "Present"
        Name            = "Default Web Site"
        State           = "Stopped"
        PhysicalPath    = "C:\inetpub\wwwroot"
        #DependsOn       = "[WindowsFeature]IIS"
    }

    xWebsite EnsureKibanaSite
    {
        Ensure          = "Present"
        Name            = "Kibana"
        State           = "Started"
        PhysicalPath    = $KibanaDestinationPath
        #DependsOn       = "[File]EnsureKibanaSource"
    }
}
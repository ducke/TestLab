configuration xElasticSearch
{
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $ESSourcePath,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $ESDestinationPath

    )
    Import-DSCResource -ModuleName xNetworking

    Package EnsureJDK
    {
        Ensure = "Present"
        Name = "Java SE Development Kit 8u11"
        Path = "$ESSourcePath\jdk1.8.0_11_x64\jdk1.8.0_11.msi"
        ProductId = '64A3A4F4-B792-11D6-A78A-00B0D0180110'
        Arguments = 'REBOOT=ReallySuppress /qn'
    }

    Environment EnvironmentExample
    {
        Ensure = "Present"
        Name = "JAVA_HOME"
        Value = "C:\Program Files\Java\jdk1.8.0_11"
    }


    File EnsureELKSource
    {
            Type = 'Directory'
            SourcePath = "$ESSourcePath\elasticsearch-1.3.2"
            DestinationPath = $ESDestinationPath
            Ensure = "Present"
            Recurse = $true
    }

    File EnsureModulePath
    {
            Type = 'Directory'
            DestinationPath = "C:\LogData"
            Ensure = "Present"
    }

    File EnsureELKConfigFile
    {
            Type = 'File'
            SourcePath = "$ESSourcePath\elasticsearch.yml"
            DestinationPath = "$ESDestinationPath\config\elasticsearch.yml"
    }

    File EnsureELKBatch
    {
            Type = 'File'
            SourcePath = "$ESSourcePath\elasticsearch.bat"
            DestinationPath = "$ESDestinationPath\bin\elasticsearch.bat"
    }

    File EnsureELKServiceBatch
    {
            Type = 'File'
            SourcePath = "$ESSourcePath\service.bat"
            DestinationPath = "$ESDestinationPath\bin\service.bat"
    }

    xFirewall AllowELKFirewall
    {
        Name                  = "ELK Firewall"
        DisplayName           = "Firewall Rule for elasticsearch"
        Ensure                = "Present"
        Access                = "Allow"
        State                 = "Enabled"
        Profile               = ("Domain","Private")
        Direction             = "Inbound"
        LocalPort             = ("9200", "9300")
        Protocol              = "TCP"
        Description           = "Firewall Rule for Notepad.exe"
    }

    Script InstallELKService
    {
        SetScript = {

            & "C:\ElasticSearch\bin\Service.bat" --% install > C:\ElasticSearch\InstService.log 2<&1
        }
        TestScript = {
            if (Get-Service elasticsearch-service-x64 -ErrorAction SilentlyContinue)
            {
                return $true
            }
            else
            {
                return $false
            }
        }
        GetScript = {
            return Get-Service elasticsearch-service-x64 | group status -AsHashTable
        }
    }

    Service ServiceElasticSearch
    {
        Name = "elasticsearch-service-x64"
        StartupType = "Automatic"
        State = "Running"
    }
}

#ELK -ESSourcePath "\\dc01.test.lab\sources\elasticsearch" -ESDestinationPath "C:\ElasticSearch"

#Start-DscConfiguration -Path .\ELK -Verbose -Wait
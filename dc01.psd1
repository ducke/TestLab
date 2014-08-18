$config = @{
    AllNodes = @(
        @{
            NodeName = "localhost"

            IPAddress  = "192.168.100.1"
            InterfaceAlias = "Ethernet"
            DefaultGateway = "192.168.100.100"
            SubnetMask     = 24
            AddressFamily  = "IPv4"

            DomainName = "ELKDemo"
            DomainFullName = "ELKDemo.local"
            DomainAccount = "Administrator"

            PSDscAllowPlainTextPassword = $true
        }
    )
}

Configuration CreateDC01
{
    param(
        $domainAdminCred
    )

    Import-DscResource -Module xNetworking,xActiveDirectory

    node localhost
    {
        xIPAddress setStaticIPAddress
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            DefaultGateway = $Node.DefaultGateway
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily
        }

        xDNSServerAddress setDNS
        {
            Address        = $Node.DnsAddress
            InterfaceAlias = $Node.InterfaceAlias
            AddressFamily  = $Node.AddressFamily

            DependsOn = "[xIPAddress]setStaticIPAddress"
        }

        WindowsFeature DCFeature
        {
            Ensure = "Present"

            Name      = "AD-Domain-Services"

            DependsOn = "[xDNSServerAddress]setDNS"
        }

        xADDomain CreateForest
        {
            DomainName = $Node.DomainFullName
            DomainAdministratorCredential = $domainAdminCred
            SafemodeAdministratorPassword = $domainAdminCred

            DependsOn = "[WindowsFeature]DCFeature"
        }
    }
}

$domainAdminCred = Get-Credential -UserName "ELKDemo\Administrator" -Message "Enter password for private domain Administrator"

CreateDC01 -ConfigurationData $config -domainAdminCred $domainAdminCred
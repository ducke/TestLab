Configuration GetMofFile
{

    param(
    $domainAdminCred
    )

    Import-DscResource -Module xNetworking,xActiveDirectory

    Node $AllNodes.Where{$_.Role -eq "PDC" }.Nodename
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

        LocalConfigurationManager
        {

            RebootNodeIfNeeded = $true
        }
    }
    Node $AllNodes.Where{$_.Role -eq "SRV" }.NodeName
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

        LocalConfigurationManager
        {

            RebootNodeIfNeeded = $true
        }
    }
}


$domainAdminCred = Get-Credential -UserName "ELKDemo\Administrator" -Message "Enter password for private domain Administrator"

GetMofFile -ConfigurationData $PSScriptRoot\ConfigData.psd1 -domainAdminCred $domainAdminCred

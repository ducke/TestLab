Configuration xBaseConf
{
    param
    (
        $IPAddress,
        $InterfaceAlias,
        $DefaultGateway,
        $SubnetMask,
        $AddressFamily,
        $DNSAddress
    )

    # Import the module that defines custom resources
    Import-DscResource -Module xNetworking

    xIPAddress setStaticIPAddress
    {
        IPAddress      = $IPAddress
        InterfaceAlias = $InterfaceAlias
        DefaultGateway = $DefaultGateway
        SubnetMask     = $SubnetMask
        AddressFamily  = $AddressFamily
    }

    xDNSServerAddress setDNS
    {
        Address        = $DnsAddress
        InterfaceAlias = $InterfaceAlias
        AddressFamily  = $AddressFamily

        DependsOn = "[xIPAddress]setStaticIPAddress"
    }

}
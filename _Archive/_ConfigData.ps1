@{
    AllNodes = @(
        @{
            NodeName = "*"

            InterfaceAlias = "Ethernet"
            DefaultGateway = "192.168.100.254"
            SubnetMask     = 24
            AddressFamily  = "IPv4"

            DnsAddress = "192.168.100.1"

            DomainName = "ELKDemo"
            DomainFullName = "ELKDemo.local"
            DomainAccount = "Administrator"

        },
        @{
            NodeName = "DC01"
            Role = "PDC"

            IPAddress  = "192.168.100.1"
        },
        @{
            NodeName = "SRV01"
            Role = "ELK"

            IPAddress  = "192.168.100.10"
        }
    )
}
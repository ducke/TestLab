powershell -c {
    Configuration DSCTemplate
    {

        Import-DscResource -Module xNetworking
        Import-DscResource -Module xComputerManagement

        node ("localhost")
        {
                xIPAddress IPAddress
            {
                InterfaceAlias = "Ethernet"
                IPAddress = "10.10.1.1"
                AddressFamily = "IPv4"
                DefaultGateway = "10.10.1.254"
                SubnetMask = 24
            }

            xDNSServerAddress DNSAddress
            {
                InterfaceAlias = "Ethernet"
                Address = "10.10.1.1"
                AddressFamily = "IPv4"
                DependsOn = "[xIPAddress]IPAddress"
            }

            xComputer ComputerConfiguration
            {
                Name = "DSCTemplate"
                DependsOn = "[xIPAddress]IPAddress"
            }

            LocalConfigurationManager
            {
                RebootNodeIfNeeded = $true
            }
        }
    }
    # Compile the configuration file to a MOF format
    DSCTemplate

    # Run the configuration on localhost
    Start-DscConfiguration -Path .\DSCTemplate -ComputerName localhost -Wait -Force -Verbose
}

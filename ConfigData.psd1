@{
    AllNodes = @(
        @{
            NodeName = "*"

            InterfaceAlias = "Ethernet"
            DefaultGateway = "192.168.100.100"
            SubnetMask     = 24
            AddressFamily  = "IPv4"

            DnsAddress = "192.168.100.1"

            DomainName = "ELKDemo"
            DomainFullName = "ELKDemo.local"
            DomainAccount = "Administrator"

            PSDscAllowPlainTextPassword = $true

            Generation = "vhdx"
            VhdPath = "$PSScriptRoot\vm"
            VhdSrcPath = "c:\VHD\Ref_W12R2EN_unattend.vhdx"

        },
        @{
            NodeName = "DC01"
            Role = "PDC"

            IPAddress  = "192.168.100.1"
        },
        @{
            NodeName = "SRV01"
            Role = "SRV"

            IPAddress  = "192.168.100.2"
        },
        @{
            NodeName = "localhost"
            Role = "VMHost"

            MemorySize = 2GB
            MemorySizeSql = 4GB
            ProcessorCount = 4

            DemoNetworkSwitchName = "Internal"
            HostIPAddressOnInternalSwitch = "192.168.100.100"
            SubnetMask     = 24
            AddressFamily  = "IPv4"

            UnattendxmlPath = "$PSScriptRoot\deployment\unattend.xml"


            VMAdministratorName = "Administrator"
            VMAdministratorPassword = "P@ssw0rd"

            FilesToCopy = @(
                @{
                   SourcePath = "$PSScriptRoot\deployment";
                   DestinationPath = "deployment"
                   Type = "Directory"
                   Recurse = $true
                 }
                @{
                   SourcePath = "$PSScriptRoot\deployment\Run.ps1";
                   DestinationPath = "Windows\System32\Configuration\Run.ps1"
                   Type = "File"
                }
                @{
                    SourcePath = "$PSScriptRoot\DSCResources"
                    DestinationPath = "Program Files\WindowsPowerShell\Modules"
                    Type = "Directory"
                    Recurse = $true
                }
            );
            Pdc = @{
                VhdName = "dc01"
                FilesToCopy = @(
                    @{
                         SourcePath = "$PSScriptRoot\GetMofFile\dc01.mof";
                         DestinationPath = "Windows\System32\Configuration\localhost.mof"
                         Type = "Directory"
                         Recurse = $true
                    }
                    @{
                         SourcePath = "$PSScriptRoot\GetMofFile\dc01.meta.mof";
                         DestinationPath = "Windows\System32\Configuration\localhost.meta.mof"
                         Type = "File"
                    }
                    @{
                         SourcePath = "$PSScriptRoot\deployment\dc01.xml";
                         DestinationPath = "unattend.xml"
                         Type = "File"
                    }
                );
            }
            SRV01 = @{
                VhdName = "SRV01"
                FilesToCopy = @(
                    @{
                         SourcePath = "$PSScriptRoot\GetMofFile\srv01.mof";
                         DestinationPath = "Windows\System32\Configuration\localhost.mof"
                         Type = "Directory"
                         Recurse = $true
                    }
                    @{
                         SourcePath = "$PSScriptRoot\GetMofFile\srv01.meta.mof";
                         DestinationPath = "Windows\System32\Configuration\localhost.meta.mof"
                         Type = "File"
                    }
                    @{
                         SourcePath = "$PSScriptRoot\deployment\srv01.xml";
                         DestinationPath = "unattend.xml"
                         Type = "File"
                    }
                );
            };
        }
    )
}
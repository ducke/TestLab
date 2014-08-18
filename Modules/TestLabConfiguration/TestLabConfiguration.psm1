Configuration TestLab {
    param (
        $cred
    )

    Import-DSCResource -Module TestLabConfiguration
    Import-DscResource -Module xActiveDirectory,xComputerManagement,xNetworking

    Node $AllNodes.Where{$_.Role -contains "BaseConfig"}.NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xBaseConf JustAConfig
        {
            IPAddress      = $Node.IPAddress
            InterfaceAlias = $Node.InterfaceAlias
            DefaultGateway = $Node.DefaultGateway
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily
            DNSAddress     = $Node.DnsAddress
        }
    }

    Node $AllNodes.Where{$_.Role -contains "PullServer"}.NodeName
    {
        xPullServer JustAPullServer
        {
            ModulePath = $Node.ModulePath
            ConfigurationPath = $Node.ConfigurationPath
        }
    }

    Node $AllNodes.Where{$_.Role -contains "PDC"}.NodeName
    {
        xPDC JustAPDC
        {
            MachineName = $Node.NodeName
            DomainFullName = $Node.DomainFullName
            DomainAdminCred = $Cred
        }
    }

    Node $AllNodes.Where{$_.Role -contains "DC"}.NodeName
    {
        xDC JustADC
        {
            MachineName = $Node.NodeName
            DomainFullName = $Node.DomainFullName
            DomainAdminCred = $Cred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
        }
    }

    Node $AllNodes.Where{$_.Role -contains "VMHost"}.NodeName
    {
        xVirtualMachine VM
        {
            VMName = $Node.VMName
            SwitchName = $Node.SwitchName
            SwitchType = $Node.SwitchType
            VhdParentPath = $Node.VhdParentPath
            #UnattendPath = $Node.UnattendPath
            VHDPath = $Node.VHDPath
            VMStartupMemory = $Node.VMStartupMemory
            VMState = $Node.VMState
            FilesToCopy = $Node.FilesToCopy
        }
    }
}

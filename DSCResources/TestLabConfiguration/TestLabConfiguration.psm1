Function New-ZipFile {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ZipFilePath,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $PathToZip
    )
    [byte[]]$data = New-Object byte[] 22
    $data[0] = 80
    $data[1] = 75
    $data[2] = 5
    $data[3] = 6
    [System.IO.File]::WriteAllBytes($ZipFilePath,$data)
    $acl = Get-Acl -Path $ZipFilePath

    $shellObj = New-Object -ComObject "Shell.Application"
    $zipFileObj = $shellObj.NameSpace($ZipFilePath)
    if($zipFileObj -ne $null){
        $target = get-item $PathToZip
        # CopyHere might be async and we might need to wait for the Zip file to have been created full before we continue
        $zipFileObj.CopyHere($target.FullName)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($zipFileObj)
        Set-Acl -Path $ZipFilePath -AclObject $acl
    } else {
        Throw "Failed to create the zip file"
    }
}

function CreateUnAttendXml()
{
    Param(
        $templatePath,
        $targetPath,
        $machineName,
        $userName,
        $password,
        $IPAddress,
        $Gateway,
        $DNSServer
    )


    [xml] $config = [xml] (Get-Content $templatePath)

    $node = $config.unattend.settings | ? {$_.pass -eq "oobeSystem"}
    $node.component.UserAccounts.AdministratorPassword.Value = $password
    $node.component.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $password
    $node.component.UserAccounts.LocalAccounts.LocalAccount.Name = $userName

    $node = $config.unattend.settings  | where { $_.pass -eq "specialize" }
    $node.component[0].ComputerName = $machineName
    $node.component[0].AutoLogon.Username = $userName
    $node.component[0].AutoLogon.Password.Value = $password
    #$node.component[1].Interfaces.DNSServerSearchOrder.IpAddress = $DNSServer
    $node.component[1].interfaces.interface.DNSServerSearchOrder.IpAddress."#text" = $DNSServer

    #$node.component[2].Interfaces.UnicastIpAddresses.IpAddress = $IPAddress
    $node.component[2].interfaces.interface.UnicastIpAddresses.IpAddress."#text" = $IPAddress

    #$node.component[2].Interfaces.Interface.Routes.Route.NextHopAddress = $Gateway

    $targetPath = Split-Path $templatePath
    $targetPath = Join-Path $targetPath -ChildPath $machineName
    $targetPath += ".xml"

    $exist = Test-Path $targetPath
    if ($exist)
    {
        Remove-Item $targetPath -Force
    }

    $config.Save($targetPath)
}

Configuration TestLab {
    param (
        $cred
    )

    Import-DSCResource -Module TestLabConfiguration
    Import-DscResource -Module xActiveDirectory,xComputerManagement,xNetworking,xPSDesiredStateConfiguration

    Node $AllNodes.Where{$_.Role -contains "BaseConfig"}.NodeName
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
            ConfigurationMode = 'ApplyOnly'
            ConfigurationID = $Node.ConfigurationID
            RefreshMode = 'Pull'
            DownloadManagerName = 'WebDownloadManager'
            DownloadManagerCustomData = @{
                ServerUrl = 'http://192.168.100.1:8080/PSDSCPullServer.svc'
                AllowUnsecureConnection = 'true' }
        }

        CreateUnAttendXml -templatePath 'C:\dev\TestLab\unattend\unattend_IP.xml' -targetPath "c:\dev\TestLab\unattend" -machineName $Node.NodeName -userName "Administrator" -password "P@ssw0rd" -IPAddress ("{0}/{1}" -f $Node.IPAddress,$Node.SubnetMask) -DNSServer $Node.DnsAddress -Gateway $Node.DefaultGateway

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
            SourcePath = $node.SourcePath
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

    Node $AllNodes.Where{$_.Role -contains "DomJoin"}.NodeName
    {
        xDomJoin JustADomJoin
        {
            MachineName = $Node.NodeName
            DomainFullName = $Node.DomainFullName
            DomainAdminCred = $Cred
            RetryCount = $Node.RetryCount
            RetryIntervalSec = $Node.RetryIntervalSec
        }
    }

    Node $AllNodes.Where{$_.Role -contains "PullServer"}.NodeName
    {
        Registry RegistryExample
        {
            Ensure = "Present"  # You can also set Ensure to "Absent"
            Key = "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnce"
            ValueName = "RunOnce"
            ValueData = "c:\deployment\runonce.cmd"
        }

        Script Assure_PULLConfig
        {
            SetScript = {
                $global:DSCMachineStatus = 1
            }
            TestScript = {
                if ((Get-DscLocalConfigurationManager).RefreshMode -like "push")
                {
                    return $false
                }
                else
                {
                return $true
                }
            }
            GetScript = {
                $getTargetResourceResult = @{
                                      Name = "Blah";
                                      DisplayName = "DisplayName";
                                      Ensure = "Ensure"
                                    }
        $getTargetResourceResult;
            }
        }

    }

    Node $AllNodes.Where{$_.Role -contains "ElasticSearch"}.NodeName
    {
        xElasticSearch JustaElasticSearch
        {
            ESSourcePath = $node.ESSourcePath #"c:\dev\TestLab\Roles\elasticsearch"
            ESDestinationPath = $node.ESDestinationPath #"C:\ElasticSearch"
        }
    }


    Node $AllNodes.Where{$_.Role -contains "Kibana"}.NodeName
    {
        xKibana JustaKibana
        {
            KibanaSourcePath = $node.KibanaSourcePath #"c:\dev\TestLab\Roles\kibana"
            KibanaDestinationPath = $node.KibanaDestinationPath #"C:\Kibana"
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
            PullServer = "DC01"
            FilesToCopy = $Node.FilesToCopy
            FilesToCopyPullServer = $Node.PullServer.FilesToCopy
        }
    }
}

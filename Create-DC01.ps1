cd c:\dev\TestLab

#$Servers = "DC01","DC02","SRV01","SRV02"
$Servers = "DC01","SRV01"
.\Update-DSCModule.ps1 -Servers $servers


$username = "Test\administrator"
$password = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$cred = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password



Get-Module | ? ModuleBase -like "C:\Program Files\WindowsPowerShell\Modules\TestLabConfiguration\*" | Remove-Module -Force
$Data = @{
        AllNodes = @(
        @{
            NodeName = "*"
            DomainFullName = "Test.lab"
            RetryCount = 20
            RetryIntervalSec = 60
            PSDscAllowPlainTextPassword = $true

            InterfaceAlias = "Ethernet"
            DefaultGateway = "192.168.100.100"
            SubnetMask = 24
            AddressFamily = "IPv4"
            DnsAddress = "192.168.100.1"
        },
        @{
            NodeName = "DC01"
            Role = @("PDC","PullServer","BaseConfig")
            ConfigurationID = "fb3aea98-c55e-4ad2-b029-3bf3cdd8e667"
            IPAddress = "192.168.100.1"
            ModulePath = "C:\DSCPullServer\Modules"
            ConfigurationPath = "C:\DSCPullServer\Configuration"
            SourcePath = "C:\Sources"
        },
        #@{
        #     NodeName = "DC02"
        #     #Role = @("DC","BaseConfig")
        #     Role = @("BaseConfig","DC")
        #     ConfigurationID = "974aa557-b2d0-40df-8cc0-a4c5b83d742f"
        #     IPAddress = "192.168.100.2"
        # },
        @{
            NodeName = "SRV01"
            #Role = @("DC","BaseConfig")
            Role = @("BaseConfig","DomJoin","ElasticSearch","Kibana")
            ConfigurationID = "0f1f1089-4291-4a0c-8b75-287be17f3b6a"
            IPAddress = "192.168.100.3"
            ESSourcePath = "\\dc01.test.lab\SourceShare\elasticsearch"
            ESDestinationPath = "C:\ElasticSearch"
            KibanaSourcePath = "\\dc01.test.lab\SourceShare\kibana"
            KibanaDestinationPath = "C:\Kibana"
        },
        # @{
        #     NodeName = "SRV02"
        #     #Role = @("DC","BaseConfig")
        #     Role = @("BaseConfig","DomJoin")
        #     ConfigurationID = "b7821aa4-79ff-4da1-90ae-03b46031efca"
        #     IPAddress = "192.168.100.4"
        # },
        @{
            NodeName = "localhost"
            Role = "VMHost"
            VMName = $Servers
            #VMName = "DC01"
            SwitchName = "Internal"
            SwitchType = "Internal"
            VhdParentPath = "C:\VHD\Ref_W12R2EN_unattend.vhdx"
            #UnattendPath = "C:\dev\TestLab\deployment\unattend.xml"
            VHDPath = "C:\Demo\Vhd"
            VMStartupMemory = 1024MB
            VMState = "Running"
            FilesToCopy = @(
                    @{
                        SourcePath = "C:\dev\TestLab\deployment"
                        DestinationPath = "deployment"
                        Type = "Directory"
                        Recurse = $true
                     }
                    @{
                        SourcePath = "C:\dev\TestLab\deployment\Run.ps1"
                        DestinationPath = "Windows\System32\Configuration\Run.ps1"
                        Type = "File"
                    }
                    @{
                        SourcePath = "C:\dev\TestLab\unattend\unattend.xml"
                        DestinationPath = "unattend.xml"
                        Type = "File"
                    }
                    @{
                        SourcePath = "C:\dev\TestLab\TestLab\#COMPUTERNAME#.meta.mof"
                        DestinationPath = "Windows\System32\Configuration\localhost.meta.mof"
                        Type = "File"
                    }
            )
            PullServer = @{
                FilesToCopy = @(
                    @{
                        SourcePath = "C:\dev\Testlab\DSCResources\*"
                        DestinationPath = "Program Files\WindowsPowerShell\Modules"
                        Type = "Directory"
                        Recurse = $true
                    }
                    @{
                        SourcePath = "C:\dev\Testlab\DSCPullShare\Modules"
                        DestinationPath = "DSCPullServer\Modules"
                        Type = "Directory"
                        Recurse = $true
                    }
                    @{
                        SourcePath = "C:\dev\TestLab\TestLab\#COMPUTERNAME#.mof"
                        DestinationPath = "Windows\System32\Configuration\localhost.mof"
                        Type = "File"
                    }
                    @{
                        SourcePath = "C:\dev\Testlab\DSCPullShare\Configuration"
                        DestinationPath = "DSCPullServer\Configuration"
                        Type = "Directory"
                        Recurse = $true
                    }
                    @{
                        SourcePath = "C:\dev\Testlab\Roles"
                        DestinationPath = "Sources"
                        Type = "Directory"
                        Recurse = $true
                    }
                )
            }
        }
    )
}

Import-Module .\DSCResources\TestLabConfiguration\TestLabConfiguration.psm1

TestLab -ConfigurationData $Data -cred $cred
#(Get-Credential -Message "Cred" -UserName "Test\Administrator")

$data.AllNodes.Where({$_.NodeName -ne "localhost"}) | %{
    #$_.Nodename;$_.Configurationid
    copy (".\TestLab\{0}.mof" -f $_.NodeName) (".\DSCPullShare\Configuration\{0}.mof" -f $_.ConfigurationID) -Verbose
    New-DSCChecksum (".\DSCPullShare\Configuration\{0}.mof" -f $_.ConfigurationID)
}


Get-ChildItem c:\dev\TestLab\DSCResources |
    where name -NotMatch "^MSFT" |
         ForEach-Object {$_.Fullname} |
            Import-Module -PassThru |
                ForEach-Object {
                    $dest = Join-Path c:\dev\TestLab\DSCPullShare\Modules ("{0}_{1}.zip" -f $_.Name,$_.Version.ToString())
                    if(test-path $dest){
                        Remove-Item $dest -Force
                    }
                    New-ZipFile -ZipFilePath $dest -PathToZip $_.ModuleBase
                    #[System.IO.Compression.ZipFile]::CreateFromDirectory($_.ModuleBase,$dest)
                }
# Create module checksum files
Get-ChildItem c:\dev\TestLab\DSCPullShare\Modules -Filter *.zip | ForEach-Object {
    New-DSCChecksum $_.FullName
    #$newHash = (Get-FileHash $_.FullName).hash
    #[System.IO.File]::WriteAllText("$($_.FullName).checksum",$newHash)
}



Start-DSCConfiguration -Path .\Testlab -Verbose -Wait


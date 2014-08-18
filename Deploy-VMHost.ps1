Configuration GetMofFile
{

    Import-DscResource -Module xHyper-V,xNetworking

    Node $AllNodes.Where{$_.Role -eq "VMHost" }.NodeName
    {
        xVMSwitch demoNetwork
        {
            Name = $Node.DemoNetworkSwitchName
            Type = "Internal"
            Ensure = "Present"
        }

        xIPAddress setStaticIPAddress
        {
            IPAddress      = $Node.HostIPAddressOnInternalSwitch
            InterfaceAlias = "vEthernet (Internal)"
            SubnetMask     = $Node.SubnetMask
            AddressFamily  = $Node.AddressFamily
            DependsOn = "[xVMSwitch]demoNetwork"
        }

        File vmFolder
        {
            Ensure = "Present"
            DestinationPath = $Node.VhdPath
            Type = "Directory"
            DependsOn = "[xIPAddress]setStaticIPAddress"
        }

        CreateUnAttendXml -templatePath $Node.UnattendxmlPath -machineName "dc01" -userName $Node.VMAdministratorName -password $Node.VMAdministratorPassword

        xVHD "vhdPreppdc"
        {
            Name = $Node.Pdc.VhdName
            Path = $Node.VhdPath
            ParentPath = $Node.VhdSrcPath
            Generation = "Vhdx"
            Ensure = "Present"
            DependsOn = "[File]vmFolder"
        }

        xVhdFile "VHDPrep2"
        {
            VhdPath = Join-Path $Node.VhdPath -ChildPath $($Node.Pdc.VhdName + ".vhdx")

            FileDirectory = ($Node.FilesToCopy + $Node.Pdc.FilesToCopy) | % {
                MSFT_xFileDirectory {
                    SourcePath = $_.SourcePath
                    DestinationPath = $_.DestinationPath
                    Ensure = "Present"
                    Type = $_.Type
                    Recurse = $_.Recurse
                    Force = $true
                }
            }
            DependsOn = "[xVHD]vhdPreppdc"
        }
        xVMHyperV pdc
        {
            Name = "DC01"
            Ensure = "Present"
            VhDPath = Join-Path $Node.VhdPath -ChildPath $($Node.Pdc.VhdName + ".vhdx")
            SwitchName = $Node.DemoNetworkSwitchName
            State = "Running"
            Generation = $Node.Generation
            StartupMemory = $Node.MemorySize
            ProcessorCount = $Node.ProcessorCount
            DependsOn = "[xVhdFile]VHDPrep2"
        }
    }
}


function CreateUnAttendXml()
{
    Param($templatePath, $machineName, $userName, $password)


    [xml] $config = [xml] (Get-Content $templatePath)

    $node = $config.FirstChild.ChildNodes | where { $_.pass -eq "oobeSystem" }
    $node.component.UserAccounts.AdministratorPassword.Value = $password
    $node.component.UserAccounts.LocalAccounts.LocalAccount.Password.Value = $password
    $node.component.UserAccounts.LocalAccounts.LocalAccount.Name = $userName

    $node = $config.FirstChild.ChildNodes | where { $_.pass -eq "specialize" }
    $node.component[0].ComputerName = $machineName
    $node.component[0].AutoLogon.Username = $userName
    $node.component[0].AutoLogon.Password.Value = $password

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


GetMofFile -ConfigurationData $PSScriptRoot\ConfigData.psd1

Start-DscConfiguration -Verbose -Wait -Path .\GetMofFile -ComputerName localhost -force
Configuration ConfigurationTest
{
    param (
        $Computernames
    )
    Import-DscResource -Module TestLabConfiguration

    Node localhost
    {

        xVirtualMachine VM
        {
            #VMName = "Test","Test2"
            VMName = $Computernames
            SwitchName = "Internal"
            SwitchType = "Internal"
            VhdParentPath = "C:\VHD\Ref_W12R2EN_unattend.vhdx"
            UnattendPath = "C:\dev\TestLab\deployment\unattend.xml"
            #DeploymentPath =
            VHDPath = "C:\Demo\Vhd"
            VMStartupMemory = 1024MB
            VMState = "Running"
        }
    }
}

ConfigurationTest -Computernames "DC01","SRV01"
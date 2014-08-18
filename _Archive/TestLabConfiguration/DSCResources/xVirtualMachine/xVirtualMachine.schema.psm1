Configuration xVirtualMachine
{
    param
    (
    # Name of VMs
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String[]]$VMName,

    # Name of Switch to create
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$SwitchName,

    # Type of Switch to create
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$SwitchType,

    # Source Path for VHD
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$VhdParentPath,

    # Destination path for diff VHD
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$VHDPath,

    # Startup Memory for VM
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$VMStartupMemory,

    # State of the VM
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$VMState,

    # unattend.xml Path
    [ValidateNotNullOrEmpty()]
    [Parameter(Mandatory)]
    $FilesToCopy
    )

    $Generation = ([System.IO.Path]::GetExtension($VhdParentPath) -replace "\.","")
    # Import the module that defines custom resources
    Import-DscResource -Module xComputerManagement,xHyper-V

    # Install the HyperV role
#    WindowsFeature HyperV
#    {
#        Ensure = "Present"
#        Name = "Hyper-V"
#    }

    # Create the virtual switch
    xVMSwitch $switchName
    {
        Ensure = "Present"
        Name = $switchName
        Type = $SwitchType
        #DependsOn = "[WindowsFeature]HyperV"
    }

    # Check for Parent VHD file
    File ParentVHDFile
    {
        Ensure = "Present"
        DestinationPath = $VhdParentPath
        Type = "File"
        #DependsOn = "[WindowsFeature]HyperV"
    }

    # Check the destination VHD folder
    File VHDFolder
    {
        Ensure = "Present"
        DestinationPath = $VHDPath
        Type = "Directory"
        DependsOn = "[File]ParentVHDFile"
    }

     # Creae VM specific diff VHD
    foreach($Name in $VMName)
    {
        xVHD "VhD$Name"
        {
            Ensure = "Present"
            Name = $Name
            Path = $VhDPath
            Generation = $Generation
            ParentPath = $VhdParentPath
            DependsOn = "[File]VHDFolder"
        }
    }

    # Copy unattend.xml into VhD
    foreach ($Name in $VMName)
    {
        xVhdFile "VHDPrep$Name"
        {
            VhdPath = Join-Path $VhdPath -ChildPath ("{0}.{1}" -f $Name,$Generation)

            FileDirectory = $FilesToCopy | % {
                MSFT_xFileDirectory {
                    SourcePath = $_.SourcePath -replace "#COMPUTERNAME#","$Name"
                    DestinationPath = $_.DestinationPath
                    Ensure = "Present"
                    Type = $_.Type
                    Recurse = $_.Recurse
                    Force = $true
                }
            }
            DependsOn = "[xVHD]vhd$Name"
            # FileDirectory = MSFT_xFileDirectory {
            #     SourcePath = $UnattendPath
            #     DestinationPath = "unattend.xml"
            #     Ensure = "Present"
            #     Force = $true
            # }
        }

    }

    # Create VM using the above VHD
    foreach($Name in $VMName)
    {
        xVMHyperV "VMachine$Name"
        {
            Ensure = "Present"
            Name = $Name
            VhDPath = Join-Path $VhdPath -ChildPath ("{0}.{1}" -f $Name,$Generation)
            SwitchName = $SwitchName
            StartupMemory = $VMStartupMemory
            State = $VMState
            MACAddress = $MACAddress
            Generation = $Generation
            WaitForIP = $true
            DependsOn = "[xVHD]Vhd$Name"
        }
    }
}
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$VMName,
    #$ProductKey='',
    $Organization='Energized About Technology',
    $Owner='Energized About Technology',
    $TimeZone='W. Europe Standard Time',
    $AdminPassword='P@ssw0rd',
    $Edition="WindowsServer2012R2ServerStandard",
    $Ram=1024MB,
    $SourcePath="c:\dev\TestLab",
    $NetworkSwitch="CorpNet01"
)
#
# Edit unattend.xml template
#
$UnattendTemplate="C:\dev\TestLab\master_unattend.xml"
#write-verbose ("Loading unattend.xml {0}" -f $UnattendTemplate)
try
{
$Unattendfile=New-Object XML
$Unattendfile.Load($UnattendTemplate)

$Unattendfile.unattend.settings.component[0].ComputerName=$VMName
#$Unattendfile.unattend.settings.component[0].ProductKey=$ProductKey
$Unattendfile.unattend.settings.component[0].RegisteredOrganization=$Organization
$Unattendfile.unattend.settings.component[0].RegisteredOwner=$Owner
$Unattendfile.unattend.settings.component[0].TimeZone=$TimeZone
$Unattendfile.unattend.settings.Component[1].RegisteredOrganization=$Organization
$Unattendfile.unattend.settings.Component[1].RegisteredOwner=$Owner
$UnattendFile.unattend.settings.component[1].UserAccounts.AdministratorPassword.Value=$AdminPassword
$UnattendFile.unattend.settings.component[1].autologon.password.value=$AdminPassword

$UnattendXML=$SourcePath+"\"+$VMName+".xml"

$Unattendfile.save($UnattendXML)
}
catch
{
    $error[0]
}
#
# Create Virtual Machine
#
$VHDPath=(Get-VMHost).VirtualHardDiskPath
$VMPath=(Get-VMHost).VirtualMachinePath

$SourceData="c:\vhd\WS12R2D.vhdx"
$TargetData=$VHDPath+$VMName+"-"+$Edition+"-c.vhdx"

#
# Check if VM exist
#
if (get-vm $VMName -ErrorAction SilentlyContinue)
{
    write-error ("VM {0} exist! Exist script" -f $VMName)
    break
}
else
{
    write-verbose ("VM {0} not exist. Creating..." -f $VMName)
}
New-VM -name $VMName -MemoryStartupBytes $Ram -verbose
Add-VMHardDiskDrive -VMName $VMName -verbose

#
# Grab VHD file from Template
#

Copy-Item $SourceData $TargetData -verbose

#
# Inject XML file into Virtual Machine
#
Mount-diskimage $TargetData -verbose
$DriveLetter=((Get-DiskImage $TargetData | get-disk | get-partition).DriveLetter)+":"

#$Destination=$Driveletter+"\Windows\System32\Sysprep\unattend.xml"
$ScriptFolder=$DriveLetter+"\DSC\"

#
# Copy DSC Resources
#
#$dscSource = "c:\dev\DSC\Waves\*"
#$dscDest = $DriveLetter+"Program Files\WindowsPowerShell\Modules\"

$MOFFile="$SourcePath\DSCTemplate.ps1"
$MOFDest=$DriveLetter+"\dsc\DSCTemplate.ps1"



New-Item $ScriptFolder -ItemType Directory
#Copy-Item "$SourcePath\RunDSC.CMD" $ScriptFolder -verbose
Copy-Item $MOFFile $MOFDest -verbose
#Copy-Item $UnattendXML $Destination -verbose
#Copy-Item $dscSource $dscDest -recurse

Copy "$SourcePath\GetMofFile\DC01.meta.mof" ("{0}\Windows\System32\Configuration\localhost.meta.mof" -f $Driveletter) -verbose
Copy "$SourcePath\GetMofFile\DC01.mof" ("{0}\Windows\System32\Configuration\localhost.mof" -f $Driveletter) -verbose
Copy "$SourcePath\run.ps1" ("{0}\Windows\System32\Configuration\Run.ps1" -f $Driveletter) -verbose
Copy "$SourcePath\run.ps1" ("{0}Run.ps1" -f $ScriptFolder) -verbose


$RemoteReg=$DriveLetter+"\Windows\System32\config\Software"
REG LOAD 'HKLM\REMOTEPC' $RemoteReg

NEW-ITEMPROPERTY "HKLM:REMOTEPC\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "PoshStart" -Value "C:\DSC\RunDSC.CMD"

REG UNLOAD 'HKLM\REMOTEPC'

dismount-diskimage $TargetData

#
# Attach Drive
#

Set-VMHardDiskDrive -VMName $VMName -Path $TargetData

#
# Connect to default Switch
#

Connect-VMNetworkAdapter -VMName $VMName -SwitchName $NetworkSwitch -verbose

START-VM $VMName -verbose
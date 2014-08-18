param(
    $VMName,
    #$ProductKey='',
    $Organization='Energized About Technology',
    $Owner='Energized About Technology',
    $TimeZone='Eastern Standard Time',
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

#
# Create Virtual Machine
#
$VHDPath=(Get-VMHost).VirtualHardDiskPath
$VMPath=(Get-VMHost).VirtualMachinePath

$SourceData="c:\vhd\WS12R2D.vhdx"
$TargetData=$VHDPath+$VMName+"-"+$Edition+"-c.vhdx"

New-VM -name $VMName -MemoryStartupBytes $Ram
Add-VMHardDiskDrive -VMName $VMName

#
# Grab VHD file from Template
#

Copy-Item $SourceData $TargetData

#
# Inject XML file into Virtual Machine
#
Mount-diskimage $TargetData
$DriveLetter=((Get-DiskImage $TargetData | get-disk | get-partition).DriveLetter)+":"

$Destination=$Driveletter+"\Windows\System32\Sysprep\unattend.xml"
$ScriptFolder=$DriveLetter+"\ProgramData\Scripts\"
$Scriptname=$Scriptfolder+"Firstrun.ps1"
$SourceStartup=$SourcePath+"\"+$VMName+".PS1"

New-Item $ScriptFolder -ItemType Directory
Copy-Item "$SourcePath\FirstStart.CMD" $ScriptFolder
Copy-Item $SourceStartup $Scriptname
Copy-Item $UnattendXML $Destination

$RemoteReg=$DriveLetter+"\Windows\System32\config\Software"
REG LOAD 'HKLM\REMOTEPC' $RemoteReg

NEW-ITEMPROPERTY "HKLM:REMOTEPC\Microsoft\Windows\CurrentVersion\RunOnce\" -Name "PoshStart" -Value "C:\ProgramData\Scripts\FirstStart.CMD"

REG UNLOAD 'HKLM\REMOTEPC'

dismount-diskimage $TargetData

#
# Attach Drive
#

Set-VMHardDiskDrive -VMName $VMName -Path $TargetData

#
# Connect to default Switch
#

Connect-VMNetworkAdapter -VMName $VMName -SwitchName $NetworkSwitch

START-VM $VMName
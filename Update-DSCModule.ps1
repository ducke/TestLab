[CmdletBinding()]
param (
    $servers
)

write-verbose "Stopping VMs"
Get-VM $servers -verbose| Stop-VM -Force -verbose

write-verbose "Remove VMs"
Remove-VM $servers -Force -verbose

write-verbose "Deleting VMs"
del C:\demo\Vhd\ -Filter *.vhdx -Recurse -Force -verbose

write-verbose "Kill WMI Process.."
get-process wmi* | stop-process -force -verbose

write-verbose "Deleting old TestLabConfiguration Module..."
del "C:\Program Files\WindowsPowerShell\Modules\TestLabConfiguration" -Recurse -Force -verbose

write-verbose "Copy new TestLabConfiguration Module..."
copy "C:\dev\TestLab\DSCResources\TestLabConfiguration" "C:\Program Files\WindowsPowerShell\Modules" -Recurse -Force -verbose


write-verbose "Deleting old Modules/Configurations/MOFS..."
del C:\dev\TestLab\DSCPullShare\Modules\* -Force -Recurse -verbose
del C:\dev\TestLab\DSCPullShare\Configuration\* -Force -Recurse -verbose
del C:\dev\TestLab\TestLab\* -Force -Recurse -verbose
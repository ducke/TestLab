[CmdletBinding()]
param()

Begin
{
    write-verbose "Reading Config File"
    $LabConfig = [XML](Get-Content -Path "C:\dev\TestLab\Lab.config")
}
Process
{
    $VMMachines = $LabConfig.hostname.ChildNodes.ForEach({$_.tostring()})
    write-verbose ("Find {0} VM Machines" -f $VMMachines.Count)
}
End{}
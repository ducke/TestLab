Configuration DSCPullSMBShare
{
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DSCSharePath,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$DSCShareName

    )

    Import-DscResource -Name MSFT_xSmbShare

    Node $ComputerName
    {
        File DSCShare {
            Type = 'Directory'
            DestinationPath = $DSCSharePath
            Ensure = 'Present'
        }

        xSmbShare ScriptingShare
        {
            Ensure = 'present'
            Name   = $DSCShareName
            Path = $DSCSharePath
            Description = 'DSC Pull Share'
            FullAccess = 'Everyone'
            DependsOn = "[File]DSCShare"
        }

        LocalConfigurationManager {
            ConfigurationID = ((New-CimSession | Get-CimInstance -Namespace root/CIMV2 -ClassName Win32_ComputerSystemProduct).UUID)
            ConfigurationMode="ApplyAndMonitor"
            ConfigurationModeFrequencyMins = 45
            RebootNodeIfNeeded = $True
            RefreshFrequencyMins = 30
            RefreshMode = "PULL"
            AllowModuleOverwrite = $True
            DownloadManagerName = "DSCFileDownloadManager"
            DownloadManagerCustomData = (@{SourcePath = "\\$computername\$DSCShareName"})
        }
    }
}
DSCPullSMBShare -DSCSharePath "C:\DSCShare" -DSCShareName "DSCShare" -ComputerName "Test"
Set-DscLocalConfigurationManager -Path .\DSCPullSMBShare -Verbose -ThrottleLimit 1
Start-DscConfiguration -Path .\DSCPullSMBShare -ComputerName localhost -Force -Wait -Verbose
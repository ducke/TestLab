netsh advfirewall firewall set rule group=@FirewallAPI.dll,-28502 new enable=yes
powershell -c Set-ExecutionPolicy RemoteSigned -Force
powershell -c enable-PSRemoting -Force
powershell -c Set-Item WSMan:\localhost\Client\TrustedHosts * -Force
wevtutil.exe set-log "Microsoft-Windows-Dsc/Analytic" /q:true /e:true
wevtutil.exe set-log "Microsoft-Windows-Dsc/Debug" /q:True /e:true
powershell -c Set-DscLocalConfigurationManager -Path c:\windows\system32\configuration
REM c:\windows\system32\schtasks.exe /Create /SC ONSTART /TN "\Microsoft\Windows\DSC\TriggerDSConBoot" /RU System /F /TR "powershell.exe -c C:\windows\system32\configuration\run.ps1"
IF EXIST C:\windows\system32\configuration\localhost.mof (
    powershell.exe -c C:\deployment\run.ps1
) else (
    powershell.exe -c C:\deployment\Check-DSCWebService.ps1 -RetryCount 5 -RetryIntervalSec 5 -WebServer "192.168.100.1" -Verbose
    powershell -NonInt -Window Hidden -Command "Invoke-CimMethod -Namespace root/Microsoft/Windows/DesiredStateConfiguration -Cl MSFT_DSCLocalConfigurationManager -Method PerformRequiredConfigurationChecks -Arguments @{Flags = [System.UInt32]1}"
)


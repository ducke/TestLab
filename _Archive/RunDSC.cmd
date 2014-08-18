netsh advfirewall firewall set rule group=@FirewallAPI.dll,-28502 new enable=yes
powershell -c Set-ExecutionPolicy RemoteSigned -Force
powershell -c enable-PSRemoting -Force
powershell -c Set-Item WSMan:\localhost\Client\TrustedHosts * -Force
powershell -c Set-DscLocalConfigurationManager -Path c:\windows\system32\configuration
c:\windows\system32\schtasks.exe /Create /SC ONSTART /TN "\Microsoft\Windows\DSC\TriggerDSConBoot" /RU System /F /TR "powershell.exe -c C:\windows\system32\configuration\run.ps1"
powershell.exe -c C:\DSC\run.ps1
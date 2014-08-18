#
# xSQLServerInstall: DSC resource to install Sql Server Enterprise version.
#


#
# The Get-TargetResource cmdlet.
#
function Get-TargetResource
{
    param
    (	
        [parameter(Mandatory)] 
        [string] $InstanceName = "MSSQLSERVER",
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,

        [PSCredential] $SourcePathCredential,

        [string] $Features="SQLEngine,SSMS",

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential
    )

    $list = Get-Service -Name MSSQL*
    $retInstanceName = $null

    if ($InstanceName -eq "MSSQLSERVER")
    {
        if ($list.Name -contains "MSSQLSERVER")
        {
            $retInstanceName = $InstanceName
        }
    }
    elseif ($list.Name -contains $("MSSQL$" + $InstanceName))
    {
        Write-Verbose -Message "SQL Instance $InstanceName is present"
        $retInstanceName = $InstanceName
    }


    $returnValue = @{
        InstanceName = $retInstanceName
    }

    return $returnValue
}


#
# The Set-TargetResource cmdlet.
#
function Set-TargetResource
{
    param
    (	
        [parameter(Mandatory)] 
        [string] $InstanceName = "MSSQLSERVER",
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,

        [PSCredential] $SourcePathCredential,

        [string] $Features="SQLEngine,SSMS",

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential
    )

    $LogPath = Join-Path $env:SystemDrive -ChildPath "Logs"

    if (!(Test-Path $LogPath))
    {
        New-Item $LogPath -ItemType Directory
    }

    $logFile = Join-Path $LogPath -ChildPath "sqlInstall-log.txt"

    $saPwd = $SqlAdministratorCredential.GetNetworkCredential().Password
    
    $cmd = Join-Path $SourcePath -ChildPath "Setup.exe"

    $cmd += " /Q /ACTION=Install /IACCEPTSQLSERVERLICENSETERMS /UpdateEnabled=false /IndicateProgress "
    $cmd += " /FEATURES=$Features /INSTANCENAME=$InstanceName "
    $cmd += " /SQLSVCACCOUNT='NT AUTHORITY\Network Service'  /SQLSYSADMINACCOUNTS='NT AUTHORITY\System' /AGTSVCACCOUNT='NT AUTHORITY\Network Service'  "
    $cmd += " /SECURITYMODE=SQL /SAPWD=$saPwd "
    $cmd += " > $logFile 2>&1 "

    NetUse -SharePath $SourcePath -SharePathCredential $SourcePathCredential -Ensure "Present"
    try
    {
        Invoke-Expression $cmd
    }
    finally
    {
        NetUse -SharePath $SourcePath -SharePathCredential $SourcePathCredential -Ensure "Absent"
    }

    # Tell the DSC Engine to restart the machine
    $global:DSCMachineStatus = 1
}

#
# The Test-TargetResource cmdlet.
#
function Test-TargetResource
{
    param
    (	
        [parameter(Mandatory)] 
        [string] $InstanceName = "MSSQLSERVER",
        
        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [string] $SourcePath,

        [PSCredential] $SourcePathCredential,

        [string] $Features="SQLEngine,SSMS",

        [parameter(Mandatory)] 
        [ValidateNotNullOrEmpty()]
        [PSCredential] $SqlAdministratorCredential
    )

    $info = Get-TargetResource -InstanceName $InstanceName -SourcePath $SourcePath -SqlAdministratorCredential $SqlAdministratorCredential
    
    return ($info.InstanceName -eq $InstanceName)
}



function NetUse
{
    param
    (	   
        [parameter(Mandatory)] 
        [string] $SharePath,
        
        [PSCredential]$SharePathCredential,
        
        [string] $Ensure = "Present"
    )

    if ($null -eq $SharePathCredential)
    {
        return;
    }

    Write-Verbose -Message "NetUse set share $SharePath ..."

    if ($Ensure -eq "Absent")
    {
        $cmd = "net use $SharePath /DELETE"
    }
    else 
    {
        $cred = $SharePathCredential.GetNetworkCredential()
        $pwd = $cred.Password 
        $user = $cred.Domain + "\" + $cred.UserName
        $cmd = "net use $SharePath $pwd /user:$user"
    }

    Invoke-Expression $cmd
}

Export-ModuleMember -Function *-TargetResource

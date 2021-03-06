data localizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
DatabaseServerCouldNotBeCreatedError=Could not create database in the following location: "{0}". Verify you did not exceed database server limit.
DatabaseServerNotExistsError=Database server "{0}" does not exist. You have to specify name of existing server.
'@
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$ServerCredential,
        
        [parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

        [parameter(Mandatory = $true)]
		[System.String]
		$RuleName,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleStartIPAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleEndIPAddress
	)

    # Verify that database server with given name exists
    Write-Verbose "Verifying that server '$ServerName' exists"
    
    try {
        $server = Get-AzureSqlDatabaseServer -ServerName $ServerName -ErrorAction Stop
        Write-Verbose "Server '$ServerName' exists"
    } catch [System.Exception] {
        # Throw exception if specified ServerName does not exist
        $errorMessage = $($LocalizedData.DatabaseServerNotExistsError) -f ${ServerName} 
        $errorMessage += "`nException message: `n" + $_
        Throw-InvalidOperationException -errorId "DatabaseServerNotExistsFailure" -errorMessage $errorMessage
    }

    $nameState = $Name
    $maxSizeGBState = $null
    $collationState = $null
    $editionState = $null
    $serverCredentialState = $null
    $serverNameState = $ServerName
    $ruleNameState = $RuleName
    $ruleStartIPAddressState = $null
    $ruleEndIPAddressState = $null
    $ensureState = $null

    # Get firewall rule state
    $currentFirewallRule = Get-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName $RuleName  -ErrorAction SilentlyContinue
    Write-Verbose "Getting status of firewall rule '$RuleName'"
    if ($currentFirewallRule) {
        $ruleStartIPAddressState = $currentFirewallRule.StartIPAddress
        $ruleEndIPAddressState = $currentFirewallRule.EndIPAddress
    }

    # Get database state
    Write-Verbose "Creating database server context for $ServerName"
    $databaseServerContext = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $ServerCredential

    Write-Verbose "Checking whether Azure SQL database '$Name' exists"
    $currentDatabase = Get-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -ErrorAction SilentlyContinue

    Write-Verbose "Getting status of database '$Name'"
    if ($currentDatabase) {
        $maxSizeGBState = $currentDatabase.MaxSizeGB
        $collationState = $currentDatabase.CollationName
        $editionState = $currentDatabase.Edition
        $ensureState = "Present"
        
    } else {
        $ensureState = "Absent"
    }

	$returnValue = @{
		Name = $nameState
		MaxSizeGB = $maxSizeGBState
		Collation = $collationState
		Edition = $editionState
		ServerCredential = $serverCredentialState
		ServerName = $serverNameState
		RuleName = $ruleNameState
		RuleStartIPAddress = $ruleStartIPAddressState
		RuleEndIPAddress = $ruleEndIPAddressState
		Ensure = $ensureState
	}

	$returnValue
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.UInt32]
		$MaxSizeGB = 1,

		[System.String]
		$Collation = "SQL_Latin1_General_CP1_CI_AS",

		[System.String]
		$Edition = "Web",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$ServerCredential,

        [parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

        [parameter(Mandatory = $true)]
		[System.String]
		$RuleName,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleStartIPAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleEndIPAddress,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present"
	)
    # Verify that database server with given name exists
    Write-Verbose "Verifying that server '$ServerName' exists"
    
    try {
        $server = Get-AzureSqlDatabaseServer -ServerName $ServerName -ErrorAction Stop
        Write-Verbose "Server '$ServerName' exists"
    } catch [System.Exception] {
        # Throw exception if specified ServerName does not exist
        $errorMessage = $($LocalizedData.DatabaseServerNotExistsError) -f ${ServerName} 
        $errorMessage += "`nException message: `n" + $_
        Throw-InvalidOperationException -errorId "DatabaseServerNotExistsFailure" -errorMessage $errorMessage
    }

    # Check whether firewall rule exists
    Write-Verbose "Checking whether SQL database server firewall rule '$RuleName' exists"
    $firewallRuleExists = $false
 
    $currentFirewallRule = Get-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName $RuleName  -ErrorAction SilentlyContinue
    if ($currentFirewallRule) {
        $firewallRuleExists = $true
        Write-Verbose "SQL database server firewall rule '$RuleName' exists"
    } else {
        Write-Verbose "SQL database server firewall rule '$RuleName' does not exist"
    }

    # If we want to ensure database is present
    if ($Ensure -eq "Present")
    {
        # Create firewall rule if not exists
        if (-not $firewallRuleExists) {
            Write-Verbose "Creating firewall rule '$RuleName'"
            New-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName $RuleName -StartIpAddress $RuleStartIPAddress -EndIpAddress $RuleEndIPAddress -ErrorAction Stop | Out-Null
        } else {
            Write-Verbose "Updating firewall rule '$RuleName'"
            Set-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName $RuleName -StartIpAddress $RuleStartIPAddress -EndIpAddress $RuleEndIPAddress -ErrorAction Stop | Out-Null
        }
        
        # Create database server context
        Write-Verbose "Creating database server context for $ServerName"
        $databaseServerContext = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $ServerCredential

        Write-Verbose "Checking whether Azure SQL database '$Name' exists"
        $database = Get-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -ErrorAction SilentlyContinue

        if ($database) {
            Write-Verbose "Azure SQL database '$Name' exists."
            
            # Get passed values
            $splat = @{}
            $value = $null

            $paramName = "MaxSizeGB"
            if ($PSBoundParameters.TryGetValue($paramName, [ref]$value)) {
                $splat.Add($paramName, $value)
            }
            
            $paramName = "Edition"
            if ($PSBoundParameters.TryGetValue($paramName, [ref]$value)) {
                $splat.Add($paramName, $value)
            }

            if ($splat.Count -ne 0) {
                # Update database with passed values
                Write-Verbose "Updating database '$Name' with properties specified by user."
                $database = Set-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name @splat -ErrorAction Stop
            } else {
                Write-Verbose "No need for updating database '$Name' cause no additional properties were passed by the user."
            }

            # If user specified collation which is different than current one, delete and recreate database (collation cannot be changed)
            $paramName = "Collation"
            if ($PSBoundParameters.TryGetValue($paramName, [ref]$value)) {
                if ($value -ne $database.CollationName) {
                    Write-Verbose "Collation was specified with value '$value' which is different than current collation: '$($database.CollationName)'. Will remove and recreate database."
                    Remove-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -Force
                    Write-Verbose "Azure SQL database '$Name' has been removed. Recreating it..."
                    $database = New-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -MaxSizeGB $MaxSizeGB -Collation $Collation -Edition $Edition -ErrorAction Stop
                    Write-Verbose "Azure SQL database '$Name' has been created"
                }
            }

        } else {
            Write-Verbose "Azure SQL database '$Name' does not exist. Creating it..."
            if ($Collation) {
                $database = New-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -MaxSizeGB $MaxSizeGB -Collation $Collation -Edition $Edition -ErrorAction Stop
            } else {
                $database = New-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -MaxSizeGB $MaxSizeGB -Edition $Edition -ErrorAction Stop
            }
            Write-Verbose "Azure SQL database '$Name' has been created"
        }
    }
    # If we want to ensure database is absent
    elseif ($Ensure -eq "Absent")
    {
        # Create database server context
        Write-Verbose "Creating database server context for $ServerName"
        $databaseServerContext = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $ServerCredential

        # Remove firewall rule
        if ($firewallRuleExists) {
            Write-Verbose "Firewall rule '$RuleName' exists. Removing it..."
            Remove-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName $RuleName
            Write-Verbose "Firewall rule '$RuleName' has been removed."
        } else {
            Write-Verbose "Firewall rule '$RuleName' does not exist. No need to remove."
        }

        # Remove database
        Write-Verbose "Checking whether Azure SQL database '$Name' exists."
        $database = Get-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -ErrorAction SilentlyContinue

        if ($database) {
            Write-Verbose "Azure SQL database '$Name' exists. Removing it..."
            Remove-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -Force
            Write-Verbose "Azure SQL database '$Name' has been removed."
        } else {
            Write-Verbose "Azure SQL database '$Name' does not exist. No need to remove."
        }
    }
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[System.String]
		$Name,

		[System.UInt32]
		$MaxSizeGB = 1,

		[System.String]
		$Collation = "SQL_Latin1_General_CP1_CI_AS",

		[System.String]
		$Edition = "Web",

		[parameter(Mandatory = $true)]
		[System.Management.Automation.PSCredential]
		$ServerCredential,

        [parameter(Mandatory = $true)]
		[System.String]
		$ServerName,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleName,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleStartIPAddress,

		[parameter(Mandatory = $true)]
		[System.String]
		$RuleEndIPAddress,

		[ValidateSet("Present","Absent")]
		[System.String]
		$Ensure = "Present"
	)
    
    $testResult = $true;

    if ($Ensure -eq "Present")
    {
        # Verify that database server with given name exists
        Write-Verbose "Verifying that server '$ServerName' exists"
    
        try {
            $server = Get-AzureSqlDatabaseServer -ServerName $ServerName -ErrorAction Stop
            Write-Verbose "Server '$ServerName' exists"
        } catch [System.Exception] {
            # Throw exception if specified ServerName does not exist
            $errorMessage = $($LocalizedData.DatabaseServerNotExistsError) -f ${ServerName} 
            $errorMessage += "`nException message: `n" + $_
            Throw-InvalidOperationException -errorId "DatabaseServerNotExistsFailure" -errorMessage $errorMessage
        }

        # Check whether firewall rule is in desired state
        Write-Verbose "Checking whether SQL database server firewall rule '$RuleName' exists"

        $currentFirewallRule = Get-AzureSqlDatabaseServerFirewallRule -ServerName $ServerName -RuleName $RuleName  -ErrorAction SilentlyContinue
        if ($currentFirewallRule) {
            # Check whether current firewall rule properties match the specified ones
            if($currentFirewallRule.StartIpAddress.Equals($RuleStartIPAddress) -and $currentFirewallRule.EndIpAddress.Equals($RuleEndIPAddress)) {
                Write-Verbose "SQL database server firewall rule '$RuleName' exists and properties match."
            } else {
                $testResult = $false
                Write-Verbose "SQL database server firewall rule '$RuleName' exists but properties don't match. Resource is not in desired state."
            }
        } else {
            Write-Verbose "SQL database server firewall rule '$RuleName' does not exist. Resource is not in desired state."
            $testResult = $false
        }

        # Check whether database is in desired state
        Write-Verbose "Creating database server context for $ServerName"
        $databaseServerContext = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $ServerCredential

        Write-Verbose "Checking whether Azure SQL database '$Name' exists"
        $currentDatabase = Get-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -ErrorAction SilentlyContinue

        if ($currentDatabase) {
        
            # Check whether current database properties match the specified ones
            if ($currentDatabase.Edition.Equals($Edition) -and ($currentDatabase.MaxSizeGB -eq $MaxSizeGB) -and $currentDatabase.CollationName.Equals($Collation)) {
                Write-Verbose "Azure SQL database '$Name' exists and properties match."
            } else {
                $testResult = $false
                Write-Verbose "Azure SQL database '$Name' exists but properties don't match. Resource is not in desired state."
            }
        } else {
            Write-Verbose "Azure SQL database '$Name' does not exist. Resource is not in desired state."
            $testResult = $false
        }
    } 
    elseif ($Ensure -eq "Absent") 
    {
        # Check whether database is in desired state
        Write-Verbose "Creating database server context for $ServerName"
        $databaseServerContext = New-AzureSqlDatabaseServerContext -ServerName $ServerName -Credential $ServerCredential

        Write-Verbose "Checking whether Azure SQL database '$Name' exists"
        $currentDatabase = Get-AzureSqlDatabase -ConnectionContext $databaseServerContext -DatabaseName $Name -ErrorAction SilentlyContinue

        if ($currentDatabase) {
            Write-Verbose "Azure SQL database '$Name' exists. Resource is not in desired state."
            $testResult = $false
        }
    }

	return $testResult
}

# Throws terminating error of category InvalidOperation with specified errorId and errorMessage
function Throw-InvalidOperationException
{
    param(
        [parameter(Mandatory = $true)]
        [System.String] 
        $errorId,
        [parameter(Mandatory = $true)]
        [System.String]
        $errorMessage
    )
    
    $errorCategory = [System.Management.Automation.ErrorCategory]::InvalidOperation
    $exception = New-Object System.InvalidOperationException $errorMessage 
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

Export-ModuleMember -Function *-TargetResource


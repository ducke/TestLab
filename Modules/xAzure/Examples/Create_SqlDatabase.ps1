<#
    Configuration creates Azure SQL Database
#>
configuration CreateSqlDatabase {
    param
    (
        $workingDirectory,
        $credential,
        $azureSubscriptionName,
        $azurePublishSettingsFile,
        $name,
        $serverCredential,
        $serverName,
        $ruleName,
        $ruleStartIPAddress,
        $ruleEndIPAddress
    )

    Import-DscResource -Module xAzure
    # Verify working directory    if ((test-path $workingDirectory) -eq $false) {        Write-Warning 'The working directory does not exist.  Exiting script.'        Exit    }

    node localhost {
         
        xAzureSubscription MSDN        {            Ensure = 'Present'            AzureSubscriptionName = $azureSubscriptionName            AzurePublishSettingsFile = $azurePublishSettingsFile        }
        
	    xAzureSqlDatabase db {

		    Name = $name
		    ServerCredential = $serverCredential
		    ServerName = $serverName
		    RuleName = $ruleName
		    RuleStartIPAddress = $ruleStartIPAddress
		    RuleEndIPAddress = $ruleEndIPAddress
            DependsOn = '[xAzureSubscription]MSDN'
	    }
    }
}

$script:configData = 
@{  
    AllNodes = @(       
                    @{    
                        NodeName = "localhost"  
                        Role = "TestHost"  
                        PSDscAllowPlainTextPassword = $true;  
                    };  
                );      
}  

# Set the folder where your files will live$workingDirectory = 'C:\Data\DSC\Resources\xAzureSqlDatabase\Examples'

$azureSubscriptionName = 'Visual Studio Ultimate with MSDN'
$azurePublishSettingsFile = Join-Path $workingDirectory 'Visual Studio Ultimate with MSDN-5-15-2014-credentials.publishsettings'

$name = "myk9"
$securePassword = ConvertTo-SecureString "P@ssword" -AsPlainText -Force
$serverCredential = New-Object System.Management.Automation.PSCredential ("mylogin", $securePassword)
$serverName = "nokmy51wix"
$ruleName = "myrule"
$ruleStartIPAddress = "131.107.174.181"
$ruleEndIPAddress = "131.107.174.181"

CreateSqlDatabase -configurationData $script:configData -workingDirectory $workingDirectory -credential $serverCredential `
                  -azureSubscriptionName $azureSubscriptionName -azurePublishSettingsFile $azurePublishSettingsFile `
                  -name $name -serverCredential $serverCredential -serverName $serverName -ruleName $ruleName `
                  -ruleStartIPAddress $ruleStartIPAddress -ruleEndIPAddress $ruleEndIPAddress
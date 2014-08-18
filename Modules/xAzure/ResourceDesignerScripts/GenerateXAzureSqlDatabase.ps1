$Name = New-xDscResourceProperty -Name Name -Type String -Attribute Key -Description 'Name of the database' 
$MaxSizeGB = New-xDscResourceProperty -Name MaxSizeGB -Type UInt32 -Attribute Write -Description 'Maximum size of the database in GB'
$Collation = New-xDscResourceProperty -Name Collation -Type String -Attribute Write -Description 'Collation of the database'
$Edition = New-xDscResourceProperty -Name Edition -Type String -Attribute Write -Description 'Edition of the database'
$ServerCredential = New-xDscResourceProperty -Name ServerCredential -Type PSCredential -Attribute Required -Description 'Credential to the database server'
$ServerName = New-xDscResourceProperty -Name ServerName -Type String -Attribute Required -Description 'Name of the database server'
$RuleName = New-xDscResourceProperty -Name RuleName -Type String -Attribute Required -Description 'Name of the firewall rule'
$RuleStartIPAddress = New-xDscResourceProperty -Name RuleStartIPAddress -Type String -Attribute Required -Description 'Start IP address of the firewall rule'
$RuleEndIPAddress = New-xDscResourceProperty -Name RuleEndIPAddress -Type String -Attribute Required -Description 'End IP address of the firewall rule'
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent" -Description 'Ensure that database is present or absent'

New-xDscResource -Name MSFT_xAzureSqlDatabase -Property @($Name, $MaxSizeGB, $Collation, $Edition, $ServerCredential, $ServerName, $RuleName, $RuleStartIPAddress, $RuleEndIPAddress, $Ensure) -ModuleName xAzureVMResources -FriendlyName xAzureSqlDatabase

$ConfigFilePath = New-xDscResourceProperty -Name ConfigFilePath -Type String -Attribute Key
$Config = New-xDscResourceProperty -Name Config -Type String -Attribute Write
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent"
New-xDscResource –Name ce_ElasticSearchConfig -Property $ConfigFilePath,$Config,$Ensure -Path 'C:\Program Files\WindowsPowerShell\Modules\ce_ElasticSearch' -FriendlyName ce_ElasticSearchConfig
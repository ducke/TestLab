
[CmdletBinding()]
param ()
DATA localizedData
{
    # same as culture = "en-US"
ConvertFrom-StringData @'
    ErrorOpceningExistingFile=An error occurred while opening the file {0} on disk. Please examine the inner exception for details
    KeyNotExist=Key {0} not exist. Creating new one "{0}: {1}".
    CommentForKeyExist=Comment for Key {0} exist. Replacing comment "#{0}:" with "{0}: {1}".
    CommentForKeyNotExist=Comment for Key {0} not exist. Creating entry "{0}: {1}".
    ItemNotEqual=Key {0} exist but value is different. Replacing {1} with {2}.
    KeyAndItemEqual="{0}: {1}" are the same.
'@
}

Import-LocalizedData LocalizedData -FileName setConfig.psd1

$ConfigFilePath = "C:\dev\TestLab\Roles\elasticsearch\elasticsearch.yml"

$config = @{
    "node.name" = "foo2334"
}

Function Throw-TerminatingError
{
    param(
        [string] $Message,
        [System.Management.Automation.ErrorRecord] $ErrorRecord,
        [string] $ExceptionType
    )
    
    $exception = new-object "System.InvalidOperationException" $Message,$ErrorRecord.Exception
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception,"MachineStateIncorrect","InvalidOperation",$null
    throw $errorRecord
}

try
{
    $configData = get-content $ConfigFilePath -ErrorAction Stop
}
catch
{
    write-Debug "ERROR: $($_|fl * -force|out-string)"
    Throw-TerminatingError ($LocalizedData.ErrorOpeningExistingFile -f $ConfigFilePath) $_
}

$res = @{}

$configData | %{
    if ($_ -match "(?sm)(?<key>^[a-z.]+):\s+(?<value>.+?)$")
    {
        $res.Add($matches["key"],$matches["value"])
    }
}

foreach ($item in $config.GetEnumerator())
{
    if (-not ($res.ContainsKey($item.key))) {
        Write-Verbose ($LocalizedData.KeyNotExist -f $item.key,$item.Value)

        if ($configData -match ("^#{0}:" -f $item.key))
        {
            Write-Verbose ($LocalizedData.CommentForKeyExist -f $item.key,$item.Value)
            $configData = $configData -replace ("^#{0}:.+?$" -f $item.key),("{0}: {1}" -f $item.Key,$item.Value)
        }
        else
        {
            Write-Verbose ($LocalizedData.CommentForKeyNotExist -f $item.key,$item.Value)
            $configData += ("`r`n{0}: {1}" -f $item.Key,$item.Value)
        }
    }
    else
    {
        if (-not (($res[$item.Key]) -ieq $item.Value))
        {
            Write-Verbose ($LocalizedData.ItemNotEqual -f $item.key,$res[$item.Key],$item.Value)
            $configData = $configData -replace ("^{0}:.+?$" -f $item.key),("{0}: {1}" -f $item.Key,$item.Value)
        }
        else
        {
            Write-Verbose ($LocalizedData.KeyAndItemEqual -f $item.key,$item.Value)
        }
    }
}

try
{
    $configData | Set-Content -Path $ConfigFilePath -Force
}
catch
{
    write-Debug "ERROR: $($_|fl * -force|out-string)"
    Throw-TerminatingError ($LocalizedData.ErrorOpeningExistingFile -f $ConfigFilePath) $_
}

#write result to disk


#$configData -match "(?sm)(?<key>^[a-z.]+):"


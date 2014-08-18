Function New-ZipFile {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $ZipFilePath,
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        $PathToZip
    )
    [byte[]]$data = New-Object byte[] 22
    $data[0] = 80
    $data[1] = 75
    $data[2] = 5
    $data[3] = 6
    [System.IO.File]::WriteAllBytes($ZipFilePath,$data)
    $acl = Get-Acl -Path $ZipFilePath

    $shellObj = New-Object -ComObject "Shell.Application"
    $zipFileObj = $shellObj.NameSpace($ZipFilePath)
    if($zipFileObj -ne $null){
        $target = get-item $PathToZip
        # CopyHere might be async and we might need to wait for the Zip file to have been created full before we continue
        $zipFileObj.CopyHere($target.FullName)
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($zipFileObj)
        Set-Acl -Path $ZipFilePath -AclObject $acl
    } else {
        Throw "Failed to create the zip file"
    }
}

# Copy,Zip modules
#Add-Type -AssemblyName System.IO.Compression.FileSystem | out-null
Get-ChildItem "$pshome\Modules\PSDesiredStateConfiguration\PSProviders" |
    where name -NotMatch "^MSFT" |
         ForEach-Object {$_.Fullname} |
            Import-Module -PassThru |
                ForEach-Object {
                    $dest = Join-Path $DSCPullFolder ("{0}_{1}.zip" -f $_.Name,$_.Version.ToString())
                    if(test-path $dest){
                        Remove-Item $dest -Force
                    }
                    New-ZipFile -ZipFilePath $dest -PathToZip $_.ModuleBase
                    #[System.IO.Compression.ZipFile]::CreateFromDirectory($_.ModuleBase,$dest)
                }
# Create module checksum files
Get-ChildItem $DSCPullFolder -Filter *.zip | ForEach-Object {
    $newHash = (Get-FileHash $_.FullName).hash
    [System.IO.File]::WriteAllText("$($_.FullName).checksum",$newHash)
}
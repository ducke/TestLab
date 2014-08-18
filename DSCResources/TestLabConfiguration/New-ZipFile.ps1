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
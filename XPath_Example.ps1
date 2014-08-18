$xpath = @'
    //*[
        contains(
            name(),
            'Password'
        )
    ]
'@
$param = @{
    Namespace = @{
        u = "urn:schemas-microsoft-com:unattend"
    }
    #xpath = "//*[contains(name(),'Password')]"
    #xpath = "//*[contains(translate(name(),'PAS','pas'),'pass')]"
    xpath = "//*[text() = '#PASSWORD#']"
}

 #//*[contains(translate(name(),'PAS','pas'),'pass')]

$config = [xml](Get-Content -Path C:\dev\TestLab\unattend\unattend_IP_Copy.xml)
$config | Select-XML @param | Format-Table -AutoSize Node, @{
        Name = 'Value'
        Expression = { $_.Node.InnerXml }
    }


$config | Select-XML @param | ForEach-Object -Process {$_.Node.Value = "Test";$Node = $_} -End {$Node.Node.OwnerDocument.Save("c:\dev\TestLab\unattend\Updated.xml")}
$config | Select-XML @param | ForEach-Object -Process {$_.Node."#text" = "Test";$Node = $_} -End {$Node.Node.OwnerDocument.Save("c:\dev\TestLab\unattend\Updated.xml")}
$NodePassword = $config | Select-XML @param | ForEach-Object -Process {$_.Node."#text" = "Test"}


ComputerName
$_.Node."#text"

//*[text() = 'qwerty']
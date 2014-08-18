[CmdletBinding()]
param()

try
{
    $guestAccountStatus = Get-WmiObject Win32_UserAccount -filter "LocalAccount=True AND Name='Guest'" -ea 0

    if ($guestAccountStatus.Disabled)
    {
        write-verbose "Guest Account is disabled. Try to enable"
        $guestAccountStatus.disabled=$false
        [void]$guestAccountStatus.Put()
        write-verbose "Guest Account is enabled."
    }
    else
    {
        write-verbose "Guest Account is enabled."
    }
}
catch
{
    $_
    break
}
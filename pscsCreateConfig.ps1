# Create an initial psCloudstack config file
Clear-Host
Write-Host @"
Now that the psCloudstack files are in place only one more thing needs to be done; creating the psCloudstack.config file.
This file can contain multiple configurations ('zones') and each configuration consists of;

 - The zone name          This name is used to locate the configuration data in the file
 - Server address         The Cloudstack server FQDN (url without 'http://' or 'https://' prefix)
 - Secure port number     The https port number (default: 443)
 - Unsecure port number   The http port number (default: 80)
 - UseSSL                 Use https or not to connect to the Cloudstack server (Y or N)
 - The API key            The user API key for the connection (must be obtained via a Cloudstack web session)
 - The Secret key         The user Secret key for the connection (must be obtained via a Cloudstack web session)

All this information will be stored in '%LOCALAPPDATA%\psCloudstack.config' or in a file you can specify.
psCloudstack will look by default for '%LOCALAPPDATA%\psCloudstack.config' unless specified otherwise

Please obtain of of the configuration items above before proceeding

"@
$Cnt = Read-Host -Prompt "Press <Enter> to continue"
# Set defaults
$pscsCfg = Read-Host -Prompt "Specify the config file to create"
if ($pscsCfg.Length -eq 0) { $pscsCfg = "{0}\psCloudstack.config" -f $env:LocalAppData }
Write-Host ""
Write-Host "Configuration will be writte to: $pscsCfg"
Write-Host ""
# Start.....
$Another = $True
While ($Another)
{
    $Again = $True
    While ($Again)
    {
        $pscsZone = ""
        $pscsServer = ""
        $pscsSport = 443
        $pscsUport = 80
        $pscsApi = ""
        $pscsSec = ""
        # get all required data
        While ($pscsZone.Length -eq 0)   { $pscsZone   = Read-Host -Prompt " - Zone name        " }
        While ($pscsServer.Length -eq 0) { $pscsServer = Read-Host -Prompt " - Server address   " }
        $sPort   =  Read-Host -Prompt " - Secure port      "; if ($sPort) { $pscsSport = $sPort }
        $uPort   =  Read-Host -Prompt " - Unsecure port    "; if ($uPort) { $pscsUport = $uPort }
        $pscsSSL = (Read-Host -Prompt " - Use SSL (Y/[N])  ").Substring(0).ToUpper() -eq "Y"
        While ($pscsApi.Length -eq 0) { $pscsApi = Read-Host -Prompt " - API Key          " }
        While ($pscsSec.Length -eq 0) { $pscsSec = Read-Host -Prompt " - Secret key       " }
        # Verify the data
        Write-Host ""
        $Again = (Read-Host "All provided data correct? (Y/[N])").Substring(0).ToUpper() -ne "Y"
    }
    Write-Host ""
    Write-Host "Creating/Updating psCloudstack config file..........."
    $pscsCmdLine = "-Zone `"$pscsZone`" -Server `"$pscsServer`" -SecurePort $pscsSport -UnsecurePort $pscsUport -Apikey `"$pscsApi`" -Secret `"$pscsSec`" -ConfigFile `"$pscsCfg`""
    if ($pscsSSL) { $pscsCmdLine += " -UseSSL" }
    iex "Add-CSConfig $pscsCmdLine -verb"
    Write-Host ""
    $Another = (Read-Host "Add another 'zone' to the config? (Y/[N])").Substring(0).ToUpper() -eq "Y"
    Write-Host ""
}
# Ready to roll.......
Write-Host @"

You are now ready to use psCloudstack.

Start by connecting to the Cloudstack server of your choice via
PS> Connect-CSManager -ConfigFile `"$pscsCfg`" -Zone `"$pscsZone`"

To list all available psCloudstack commands, use
PS> Get-Command -Module psCloudstack

Each command provides help info the way PowerShell does, try
PS> Get-Help listVirtualMachines

Enjoy psCloudstack!

Best regards, Hans van Veen
 
"@

#psCloudstack#
A PowerShell module which dynamically creates PowerShell functions for all (to the user) available Cloudstack api's.

### Installation###
Copy **all** files to one of the following folders:
```
$Home\Documents\WindowsPowerShell\modules\psCloudstack (%UserProfile%\Documents\WindowsPowerShell\Modules\psCloudstack)      Private installation of psCloudstack
$Env:ProgramFiles\WindowsPowerShell\Modules\psCloudstack (%ProgramFiles%\WindowsPowerShell\Modules\psCloudstack)               Public installation of psCloudstack
```
Do NOT use $PSHome\Modules (%Windir%\System32\WindowsPowerShell\v1.0\Modules) This location is reserved for modules that ship with Windows.

####To activate:####
Beginning in Windows PowerShell 3.0, installed modules are automatically imported to the session when you use any commands or providers in the module. However, you can still use the Import-Module command to import the psCloudstack module

###Description:###
Coding PowerShell functions for all available Cloudstack api's.... there are more than 450 of them now! You probably think the guy is insane or has to much spare time. I am addicted, but it's neither of that. I do agree: coding 450+ functions manually is insane and that's why I came up with psCloudstack.

###The Base Functions###
The psCloudstack module consists of 7 base (static) functions which form the core of psCloudstack.

#####1. Convert-CSConfig#####
    Convert-CSConfig [-ConfigFile <string>] [-Zone <string>]
As of psCloudstack V3 there is only one configuration file: $Env:LOCALAPPDATA\psCloudstack.config (%LOCALAPPDATA%\psCloudstack.config)
Pre-V3 configuration files can be converted to the V3 file format using the Convert-CSConfig function. Without specifying a source file and configuration zonename the current psCloudstack.config file will be read, converted and updated. This zone connection configuration will be named "Default"

Specifying another configuration file will read, convert and append its zone connection data to the (new) default configuration file. If no connection name is specified "Default" will be used, but if the connection name already exists in the configuration file, the name will be appended with a "+" sign. You can use a standard editor (or the Set-CSConfig function) to modify this name.

#####2. Add-CSConfig#####
    Add-CSConfig [-Zone <string>] -Server <string> [-SecurePort <number>] [UnsecurePort <number>] -Apikey <string> -Secret <string> [-UseSSl] [-ConfigFile <string>]
Add-CSConfig kind of replaces the former Initialize-CSConfig function. It is used to add psCloudstack connection configurations to the config file.

If "Zone" already exists in the configuration file, a warning will be shown and the specified zone name will be appended with a "+". You can use a standard editor (or the Set-CSConfig function) to modify this name.

#####3. Remove-CSConfig#####
    Remove-CSConfig -Zone <string>,... [-ConfigFile ....]
Remove-CSConfig removes one or more named zone connections from the psCloudstack configuration file.

#####4. Get-CSConfig#####
    Get-CSConfig [-Zone <string>,...] [-ConfigFile <String>] [-ShowKeys] [-All]
Without any parameters it will collect the 'default' connection info.
Using -Zone will show tyhe info for the requested connection zonename, while -All will show all connection configurations.

When used interactively, all info will be displayed with exception of the api key and the secret key. If this information is required, use -ShowKeys on the command line.

By using -ConfigFile the content of another psCloudstack config file can be displayed.

#####5. Set-CSConfig#####
    Set-CSConfig -Zone <string> [-NewName <string>] [-Server <string>] [-SecurePort <number>] [UnsecurePort <number>] [-Apikey <string>] [-Secret <string>] [-UseSSl] [-ConfigFile <string>]
Set-CSConfig updates/modifies existsing psCloudstack connection configurations.

If "NewName" already exists in the configuration file, a warning will be shown and the action will be terminated.

#####6. Connect-CSManager#####
This function (and the next) are the core of psCloudstack. As mentioned before, it is impossible to code 450+ functions manually without getting RSI (or worse).

Connect-CSManager uses the Cloudstack listApis api call to collect the details of *all entitled api's* and it will turn them automatically into PowerShell functions.
The api name becomes the function name, the api request parameters become the function parameters and the api response tags become the output fields of the function.
All this information is pasted into a (Here-String based) **global** function template and than executed via the Invoke-Expression command.

```
PS C:\> Connect-CSManager -Verbose
VERBOSE: Collecting api function details for Default
Welcome to psCloudstack V3.0.0, generating 266 api functions for you
VERBOSE:  001 - listNetworkACLs
VERBOSE:  002 - reconnectHost (A)
VERBOSE:  003 - createCondition (A)
VERBOSE:  004 - copyTemplate (A)
VERBOSE:  005 - listRouters
VERBOSE:  006 - listNiciraNvpDeviceNetworks
          ...
          ...
          ...

Functions marked with an (A) use async api calls which only return job information which can be used to retrieve information of the the actual request target.
For example: deployVirtualMachine will return an item named "jobinstanceid", this is the id you can use with listVirtualMachines.
By default async function will wait for the job to complete, specifying -Wait xxx  will cause the function to wait for max. xxx seconds before returning the
job details. Use -NoWait if you do not want to wait at all.
```

#####7. Invoke-CSApiCall#####
    Invoke-CSApiCall -Command <String> [-Parameters <String[]>] [-Format <string>] [-Server <String>] [-[Un]SecurePort <Int32>] [-Apikey <String>] [-Secret <String>] [-UseSSL] [-UseUnsecure]
This function contains the actual api call logic. An Cloudstack api call has to be formatted in a specific way and signed using the users api & secret key. This process is described in detail in the "Cloudstack API Developer's Guide" chapter "Calling the Cloudstack API".

Invoke-CSApiCall is used by every api function created via Connect-CSManager (which uses it to get all the available api's), but it can also be used interactively.

At least the command must be specified and optional some parameters to the command. The other parameters can be used to override the settings from the active configuration file.        
By default Invoke-CSApiCAll will return XML formatted output, but JSON is also possible using *-Format JSON*
```
PS> Invoke-CSApiCall -Command listZones name=Bootcamp 

xml                                                               listzonesresponse
---                                                               -----------------
version="1.0" encoding="UTF-8"                                    listzonesresponse


PS> Invoke-CSApiCall -Command listZones name=Bootcamp  -Format JSON
{ "listzonesresponse" : { "count":1 ,"zone" : [  {"id":"755fba3b-a748-4458-a3d2-e149b74da94a","name":"Bootcamp","dns1":"8.8.8.8","dns2":"8.8.4.4","internaldns1":"192.168.56.11","guestcidraddress":"10.1.1.0/24","networktype":"Advanced","securitygroupsenabled":false,"allocationstate":"Enabled","zonetoken":"277b0fae-5b08-3a61-837a-b55475bac83b","dhcpprovider":"VirtualRouter","localstorageenabled":false} ] } }
```

#####8. Start-CSConsoleSession#####
    Start-CSConsoleSession [-Zone <String>] -Server <String>
This function starts a web based console session with the specified server. The server will be located in the default zone/connection, unless -Zone is used to specify a different zone.

No need to use Connect-CSManager first, Start-CSConsoleSession works autonomous. If Connect-CSManager has been called, the server will be serached for in the connected zone (unless specified otherwise.....)
# psCloudstack - a dynamic collection of PowerShell functions for maintaining a Cloudstack environment
#
#         Copyright 2014, Hans L.M. van Veen
#         
#         Licensed under the Apache License, Version 2.0 (the "License");
#         you may not use this file except in compliance with the License.
#         You may obtain a copy of the License at
#         
#             http://www.apache.org/licenses/LICENSE-2.0
#         
#         Unless required by applicable law or agreed to in writing, software
#         distributed under the License is distributed on an "AS IS" BASIS,
#         WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#         See the License for the specific language governing permissions and
#         limitations under the License.
#
############################################################################################################################
#  Set-CSConfig
#    Sets %CSCONFIGFILE% to the specified file specification, but only if that file exists!
############################################################################################################################
function Set-CSConfig {
<# 
 .Synopsis
    Set the CSCONFIGFILE environment variable

 .Description
    Set the CSCONFIGFILE environment variable to the specified or default value, but only if that file exists.
    This environment variable then specifies the active configuration and connection settings.

 .Parameter ConfigFile
    The path and name of a config file to store as %CSCONFIGFILE%.

 .Outputs
    None
    
 .Notes
    psCloudstack   : V2.1.2
    Function Name  : Set-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([parameter(Mandatory=$true)][string]$ConfigFile)
    $bndPrm = $PSBoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Verifying configuration file
    # ----------------------------------------------------------------------------------------------------------------------
    if ($ConfigFile -eq "")
    {
        $ConfigFile = "{0}\psCloudstack.config" -f $env:LocalAppData
        Write-Verbose "Using default config: $ConfigFile"
    }
    else { Write-Verbose "Using requested config: $ConfigFile" }
    if (!(Test-Path "$ConfigFile")) { throw "Specified psCloudstack configuration file not found" }
    $env:CSCONFIGFILE = $ConfigFile
}

############################################################################################################################
#  Get-CSConfig
#    Reads the configuration for the Cloudstack Management server and returns it as a system.object
############################################################################################################################
function Get-CSConfig {
<# 
 .Synopsis
    Get the configuration and connection settings from the active or requested configuration file.

 .Description
    This function gets the configuration and connection settings from the active config file. This config file, which has
    been created with Initialize-CSConfig and/or set to active with Set-CSConfig, contains the required connection info for
    connecting to the Cloudstack Management server, either via the authenticated or unauthenticated port.

    If no configuration file is specified, the value of %CSCONFIGFILE% will be used. And if that environment varaiable does
    not exist %LOCALAPPDATA%\psCloudstack.config will be used.
  
 .Parameter ConfigFile
    The path and name of a config file which contains the configuration and connection settings.
      
 .Parameter ShowKeys
    Show the API & Secret key in the output object.

 .Outputs
  psCloudstack.Config Object
    A psCloudstack.Config System.Object which contains all collected settings.
    - File             The active configurationfile
    - Server           The server to connect to
    - UseSSL           Use https for connecting
    - SecurePort       The secure port number
    - UnsecurePort     The unsecure port number
    - CommandStyle     Use Windows or Unix style commands
    - Api              The user api key (when requested)
    - Key              The user secret key (when requested)
    - Version          The LAST seen cloudstack version!
    - Count            The number of available api calls in that version
    
 .Notes
    psCloudstack   : V2.1.2
    Function Name  : Get-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([string]$ConfigFile,[switch]$ShowKeys)
    $bndPrm = $PSBoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Verifying configuration file and if found make it the active one
    # ----------------------------------------------------------------------------------------------------------------------
    if  ($ConfigFile -eq "") { $ConfigFile = $env:CSCONFIGFILE }
    if  ($ConfigFile -eq "") { $ConfigFile = "{0}\psCloudstack.config" -f $env:LocalAppData }
    if (($ConfigFile -eq "") -or !(Test-Path "$ConfigFile")) { throw "No psCloudstack configuration file found" }
    # ======================================================================================================================
    #  Read the config file connect details and store them in the connect object
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Reading psCloudstack config file"
    [xml]$cfg = gc "$ConfigFile"
    $Connect = $cfg.configuration.connect
    $Api = $cfg.configuration.api
    # ======================================================================================================================
    #  Create the output object and add all info to it
    # ----------------------------------------------------------------------------------------------------------------------
    $cfgObject = New-Object -TypeName PSObject
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name File         -Value $ConfigFile
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Server       -Value $Connect.server.address
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name UseSSL       -Value ($Connect.server.usessl -eq "true")
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name SecurePort   -Value $Connect.server.secureport
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name UnsecurePort -Value $Connect.server.unsecureport
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name CommandStyle -Value $Connect.command.style
    if ($ShowKeys)
    {
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Api -Value $Connect.authentication.api
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Key -Value $Connect.authentication.key
    }
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Version -Value $Api.version
    $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Count   -Value $Api.count
    # ======================================================================================================================
    #  All connection details are collected, write the object
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Output $cfgObject
}

############################################################################################################################
#  Initialize-CSConfig
#    Creates or updates the connection configuration for the Cloudstack Management server and api calls
#    This configuration is used by Connect-CSServer to establish a first connection and to verify the api status
############################################################################################################################
function Initialize-CSConfig {
<# 
 .Synopsis
    Creates or updates the config file required to communicate with the Cloudstack management server

 .Description
    This function creates or updates the connection config file. This file (default:
    %LOCALAPPDATA%\psCloudstack.config) contains the required connection info for communicating with
    the Cloudstack Management server, either via the authenticated or unauthenticated port.

    The config file also contains information about the last connection like Cloudstack version,
    the number of available api's. Only api's the user is entitled to are collected and counted.
  
 .Parameter Server
    The name or IP address of the Cloudstack management server. This is a required parameter.
    If a config file is updated the server IP address will be used to verify the correctness
    of the existing content

 .Parameter SecurePort
    The API secure port number.

 .Parameter UnsecurePort
    The API unsecure port number.

 .Parameter Apikey
    The users apikey. This key will be, in combination with the users secret key, be converted
    to a single hash value. This hash value will be stored in the config file.

 .Parameter Secret
    The users secret key. This key will be, in combination with the users api key, be converted
    to a single hash value. This hash value will be stored in the config file.

 .Parameter UseSSL
    Use https when connecting to the Cloudstack management server. Only used when requesting access
    via the secured port.

 .Parameter CommandStyle
    CommandStyle can be Windows or Unix and specifies how Cloudstack booleans are treated (default: Windows)
    Windows style: boolean parameters like listAll are true when specified and not used when not specified
    Unix style: boolean parameters like listAll must be given a value (true or false)

 .Parameter Config
    The path and name of a config file to which the input information is written.
    By default %LOCALAPPDATA%\psCloudstack.config will be used, but a different file can be specified.
    The full filespec is also saved in %CSCONFIGFILE% and is used by Get-CSConfig in case the
    default file cannot be found.

 .Outputs
    None
    
 .Notes
    psCloudstack   : V2.1.2
    Function Name  : Initialize-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V2

  .Example
    # Create/Update the content of the default config file

    C:\PS> Initialize-CSConfig -Server www.xxx.yyy.zzz -Api xxxxxxx -Secret yyyyyyyyy

#>
[CmdletBinding()]
param([parameter(Mandatory=$true)][string]$Server,
      [Parameter(Mandatory = $false)][int]$SecurePort=8080,
      [Parameter(Mandatory = $false)][int]$UnsecurePort=8096,
      [Parameter(Mandatory = $false)][string]$Apikey,
      [Parameter(Mandatory = $false)][string]$Secret,
      [Parameter(Mandatory = $false)][switch]$UseSSL,
      [Parameter(Mandatory = $false)][ValidateSet("Windows","Unix")] [string]$CommandStyle="Windows",
      [Parameter(Mandatory = $false)][string]$ConfigFile=("{0}\psCloudstack.config" -f $env:LocalAppData))
    $bndPrm = $PSBoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Local & Global variables
    # ----------------------------------------------------------------------------------------------------------------------
    $doUpdate = $false; $doUseSSL = ($UseSSL -and $true).ToString().ToLower()
    $sysPing = New-Object System.Net.NetworkInformation.Ping
    $ipRegex = "^\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b$"
    # ======================================================================================================================
    #  Create an empty xml template to be used as 'staging' area for an existing config or as source for a new config
    # ----------------------------------------------------------------------------------------------------------------------
    [xml]$newCfg = "<?xml version=`"1.0`" encoding=`"utf-8`"?>
                    <configuration version=`"2.0`">
                      <connect>
                        <command style=`"$CommandStyle`" />
                        <server address=`"`" secureport=`"$SecurePort`" unsecureport=`"$UnsecurePort`" usessl=`"true`" />
                        <authentication api=`"`" key=`"`"/>
                      </connect>
                      <api version=`"`" count=`"`" />
                    </configuration>"
    $newConnect = $newCfg.configuration.connect
    # ======================================================================================================================
    #  Verify the server by getting the server IP address. Try DNS lookup and if that fails try Ping
    # ----------------------------------------------------------------------------------------------------------------------
    $ServerIP = $Server
    if ($ServerIP -NotMatch $ipRegex)
    {
        try { $ServerIP = [System.Net.Dns]::GetHostAddresses("$Server")[0].IPAddressToString }
        catch
        {
            try { $ServerIP = $($sysPing.Send("$Server").Address).IPAddressToString }
            catch { throw "Cannot convert $Server to an IP address" }
        }
    }
    if ($ServerIP -NotMatch $ipRegex) { throw "Cannot convert $Server to an IP address" }
    # ======================================================================================================================
    #  Check the config file. If it exists update the new config template with its information
    # ----------------------------------------------------------------------------------------------------------------------
    if (Test-Path "$ConfigFile")
    {
        Write-Verbose "Update existing Cloudstack config file"
        [xml]$curCfg = gc "$ConfigFile"        
        $curConnect = $curCfg.configuration.connect
        if ($curConnect.command.style.length -gt 0)       { $newConnect.command.style       = $curConnect.command.style }
        if ($curConnect.server.address.length -gt 0)      { $newConnect.server.address      = $curConnect.server.address }
        if ($curConnect.server.usessl.length -gt 0)       { $newConnect.server.usessl       = $curConnect.server.usessl }
        if ($curConnect.server.secureport.length -gt 0)   { $newConnect.server.secureport   = $curConnect.server.secureport }
        if ($curConnect.server.unsecureport.length -gt 0) { $newConnect.server.unsecureport = $curConnect.server.unsecureport }
        if ($curConnect.authentication.api.length -gt 0)  { $newConnect.authentication.api  = $curConnect.authentication.api }
        if ($curConnect.authentication.key.length -gt 0)  { $newConnect.authentication.key  = $curConnect.authentication.key }
    }
    else { Write-Verbose "Create new Cloudstack config file" }
    # ======================================================================================================================
    #  Check the command line and see whether config settings are overruled. Save and activate the config when done
    # ----------------------------------------------------------------------------------------------------------------------
    if ($bndPrm.CommandStyle.length -gt 0) { $newConnect.command.style = $CommandStyle }
    if ($bndPrm.Server.length -gt 0)       { $newConnect.server.address = $Server }
    if ($bndPrm.UseSSL)                    { $newConnect.server.usessl = "true" }
    if ($bndPrm.SecurePort -gt 0)          { $newConnect.server.secureport = "$SecurePort" }
    if ($bndPrm.UnsecurePort -gt 0)        { $newConnect.server.unsecureport = "$UnsecurePort" }
    if ($bndPrm.Apikey.length -gt 0)       { $newConnect.authentication.api = $Apikey }
    if ($bndPrm.Secret.length -gt 0)       { $newConnect.authentication.key = $Secret }
    rv Apikey; rv Secret
    Write-Verbose "Update and activate connection configuration"
    $newCfg.Save($ConfigFile); Set-CSConfig "$ConfigFile"
    # ======================================================================================================================
    #  Now for the 'exiting' stuff. Get the list of entitled api's from the server and store version and count
    #  Only perform this action if we have a apikey/secretkey pair!
    # ----------------------------------------------------------------------------------------------------------------------
    if (($newConnect.authentication.api.length -gt 0) -and ($newConnect.authentication.key.length -gt 0))
    {
        $apiInfo = (Invoke-CSApiCall listApis -Format XML -Verbose:$false).listapisresponse
        Update-ApiInfo -apiVersion $apiInfo."cloud-stack-version" -apiCount $apiInfo.Count
    }
    # ----------------------------------------------------------------------------------------------------------------------
}
############################################################################################################################
#  Invoke-CSApiCall
#    This function will use the stored connection info to build and issue a valid Cloudstack api call
#    This call can either be directed to the secure or unsecure port
############################################################################################################################
function Invoke-CSApiCall {
<# 
 .Synopsis
    Build and issue a valid Cloudstack api call.

 .Description
    This function uses the connection info from the config file to build and issue a valid Cloudstack
    api call. This api call can either be directed to the secure (authentication required) port or the unsecure port.

 .Parameter Command
    The api command to issue.

 .Parameter Parameters
    A comma-separate list of additional api call parameters and values

 .Parameter Format
    Specifies the reponse output format. By default XML output is returned, the other option is JSON

 .Parameter Server
    The name or IP address of the Cloudstack management server. Using this parameter will override
    value from the the config 

 .Parameter SecurePort
    The API secure port number. Using this parameter will override value from the the config

 .Parameter UnecurePort
    The API unsecure port number. Using this parameter will override value from the the config

 .Parameter Apikey
    The users apikey.  Using this parameter will override value from the the config 
      
 .Parameter Secret
    The users secret key.  Using this parameter will override value from the the config 

 .Parameter UseSSL
    Use https when connecting to the Cloudstack management server.
    Only used when requesting access via the secured port.

 .Parameter UseUnsecure
    When this switch is specified the api call will be directed to the unsecure port


 .Outputs
    An XML or JSON formatted object which contains all content output returned by the api call
    
 .Notes
    psCloudstack   : V2.1.2
    Function Name  : Invoke-CSApiCall
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([parameter(Mandatory=$true,ValueFromPipeline=$true)][string]$Command,
      [Parameter(Mandatory = $false)][string[]]$Parameters=$null,
      [Parameter(Mandatory = $false)][ValidateSet("XML","JSON")] [string]$Format="XML",
      [Parameter(Mandatory = $false)][string]$Server,
      [Parameter(Mandatory = $false)][int]$SecurePort,
      [Parameter(Mandatory = $false)][int]$UnsecurePort,
      [Parameter(Mandatory = $false)][string]$Apikey,
      [Parameter(Mandatory = $false)][string]$Secret,
      [Parameter(Mandatory = $false)][switch]$UseSSL,
      [Parameter(Mandatory = $false)][switch]$UseUnsecure)
    $bndPrm = $PSBoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Trap all errors and return them in a fashionable way...
    # ----------------------------------------------------------------------------------------------------------------------
    trap
    {
        $errCode = "1"; $errMsg = $iwr.Message; $cmdIdent = "{0}response" -f $Command.ToLower()
        if ($errMsg -match "^\d+") { $errCode = $matches[0]; $errMsg = $errMsg.SubString($errCode.Length) }
        Write-Host "API Call Error: $errMsg" -f DarkBlue -b Yellow
        [xml]$response = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                          <$cmdIdent cloud-stack-version=`"$csVersion`">
                            <displaytext>$errMsg</displaytext>
                            <errorcode>$errCode</errorcode>
                            <success>false</success>
                          </$cmdIdent>"
        return $response
    }
    # ======================================================================================================================
    #  Local variables and definitions. Hide progress of Invoke-WebRequest 
    # ----------------------------------------------------------------------------------------------------------------------
    [void][System.Reflection.Assembly]::LoadWithpartialname("System.Web")
    $crypt = New-Object System.Security.Cryptography.HMACSHA1
    # ======================================================================================================================
    #  Get the connection details from the config file. Then see whether there are overrides....
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect = Get-CSConfig -ShowKeys
    $csVersion = $Connect.Version
    if ($Server -ne "") { $Connect.Server = $Server }
    if ($SecurePort -ne 0) { $Connect.SecurePort = $SecurePort }
    if ($UnsecurePort -ne 0) { $Connect.UnsecurePort = $UnsecurePort }
    if ($Apikey) { $Connect.api = $Apikey }
    if ($Secret) { $Connect.key = $Secret }
    if ($UseSSL) { $Connect.UseSSL = $true }
    # ======================================================================================================================
    #  If additional parameters and values are specified, format them to a valid api call query string
    #
    #  BEWARE!   We need to comply with the URL encoding standards. But the equal-sign in a parameter name/value pair
    #            has to stay! Assume the name to be compliant and only convert the value. Pitfall #2: UrlEncode
    #            replaces spaces with a + sign, but the Cloudstack api does not understand that. So replace + with %20
    # ----------------------------------------------------------------------------------------------------------------------
    $Command = ([System.Web.HttpUtility]::UrlEncode($Command)).Replace("+","%20")
    $queryString = "response={0}" -f $Format.ToLower()
    $Parameters|%{
        if ($_.Length -gt 0)
        {
            $prmName,$prmVal = $_ -Split "=",2
            $prmVal = ([System.Web.HttpUtility]::UrlEncode($prmVal)).Replace("+","%20")
            $queryString += ("&{0}={1}" -f $prmName, $prmVal)
        }
    }
    Write-Verbose "Query String: $queryString"
    # ======================================================================================================================
    #  If it is an unsecured call, issue it
    # ----------------------------------------------------------------------------------------------------------------------
    if ($UseUnsecure)
    {
        Write-Verbose "Unsecured web request for api call: $Command"
        $csUrl = "http://{0}:{1}/client/api?command={2}&{3}" -f $Connect.Server,$Connect.UnsecurePort,$Command,$queryString
        $prefProgress = $progressPreference; $progressPreference = 'silentlyContinue'
        $Response = Invoke-WebRequest "$csUrl" -ErrorVariable iwr
        $progressPreference = $prefProgress
    }
    # ======================================================================================================================
    #  Build a signed api call (URL Query String) using the details provided. Beware: Base64 does not deliver a string
    #  which complies with the URL encoding standard!
    # ----------------------------------------------------------------------------------------------------------------------
    else
    {
        Write-Verbose "Secured web request for api call: $Command"
        $cryptString = (("apikey={0}&command={1}&{2}" -f $Connect.api,$Command,$queryString).split("&")|sort) -join "&"
        $crypt.key = [Text.Encoding]::ASCII.GetBytes($Connect.key)
        $cryptBytes = $crypt.ComputeHash([Text.Encoding]::ASCII.GetBytes($cryptString.ToLower()))
        $apiSignature = [System.Web.HttpUtility]::UrlEncode([System.Convert]::ToBase64String($cryptBytes))
        Write-Verbose "Signature: $apiSignature"
        # ------------------------------------------------------------------------------------------------------------------
        #  The signature is ready, create the final url and invoke the web request
        # ------------------------------------------------------------------------------------------------------------------
        $protocol = "http"; if ($Connect.UseSSL) { $protocol = "https" }
        $baseUrl = "{0}://{1}:{2}/client/api?" -f $protocol,$Connect.Server,$Connect.SecurePort
        $csUrl = "{0}command={1}&{2}&apikey={3}&signature={4}" -f $baseUrl,$Command,$queryString,$Connect.api,$apiSignature
        $prefProgress = $progressPreference; $progressPreference = 'silentlyContinue'
        $Response = Invoke-WebRequest "$csUrl" -ErrorVariable iwr
        $progressPreference = $prefProgress
    }
    # ======================================================================================================================
    #  Now return the content in the requested format
    # ----------------------------------------------------------------------------------------------------------------------
    $Content = $Response.Content
    if ($Format -eq "XML") { [xml]$Content = $Response.Content }
    Write-Output $Content
}

############################################################################################################################
#  Connect-CSManager
#    This function will connect to the active/selected CS Manager server. It will obtain a list of available api's
#    and it will convert them into 'regular' Powershell functions. These functions will be propagated via the main
#    psCloudstack module.
############################################################################################################################
function Connect-CSManager {
<# 
 .Synopsis
    Connect to the requested Cloudstack management server and build the api functions

 .Description
    This function connects to the requested Cloudstack management server and then obtain a list of available
    api calls. This list will then be converted into 'regular' Powershell functions. These functions will be
    propagated via the main psCloudstack module.
  
    Functions for async api calls will wait util the api call completed its work, unless:
      -NoWait has been specified with the function call
    or
      -Wait xx has been specified with the function call where xx is the maximum number of seconds to wait

    When running this function with -Verbose the async api functions will be marked with a (A).
  
 .Parameter CommandStyle
    CommandStyle can be Windows or Unix and it causes Cloudstack booleans to be processed differently.
    Windows style: boolean parameters like listAll are true when specified and not used when not specified , no value required.
    Unix style: boolean parameters like listAll must be given a value (true or false).
      
    The style setting can also be specified in the config file!

 .Parameter Silent
    Suppress the welcome message

 .Outputs
    All available Cloudstack api calls as PowerShell functions

 .Example
    # Connect and prepare for windows style api functions
    C:\PS> Connect-CSManager
    Welcome to psCloudstack V2.1.2 - Generating 458 api functions for you
    
    C:\PS> listUsers -listall

    account             : admin
    accountid           : f20c65de-74b8-11e3-a3ac-0800273826cf
    accounttype         : ..........................
    
 .Example
    # Connect and prepare for unix style api functions
    C:\PS> Connect-CSManager -CommandStyle Unix
    Welcome to psCloudstack V2.1.2 - Generating 458 api functions for you
    
    C:\PS> listUsers -listall true

    account             : admin
    accountid           : f20c65de-74b8-11e3-a3ac-0800273826cf
    accounttype         : ..........................
    
    
  .Notes
    psCloudstack   : V2.1.2
    Function Name  : Connect-CSManager
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([Parameter(Mandatory = $false)][ValidateSet("Windows","Unix")] [string]$CommandStyle,[switch]$Silent)
    $bndPrm = $PSBoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ==========================================================================================================================
    #   The api parameter types differ in name from the Powershell types. Create a translation table to deal with this.
    #   The Windows and Unix command styles only differ on 1 thing: Windows switch is true when specified
    #   Beware: The unix date format yyyy-MM-dd has no counterpart in Powershell, therefore its replaced by type string
    # --------------------------------------------------------------------------------------------------------------------------
    $trnTable  = @{ "boolean" = "switch" ; "date"  = "string" ; "integer" = "int32"  ; "list" = "string[]" ; "long"   = "int64" ;
                    "map"     = "string" ; "short" = "int16"  ; "string"  = "string" ; "uuid" = "string"   ; "tzdate" = "string" }
    # ==========================================================================================================================
    #   Load the config file and determine which command style to use (commandline overrules config, default is Windows)
    #   When unix is selected, convert the translation table switch type to string.
    # --------------------------------------------------------------------------------------------------------------------------
    $Connect = Get-CSConfig -ShowKeys
    $apiVersion = $Connect.Version
    $apiCount = $Connect.Count
    $cmdStyle = $Connect.command.style
    if ($CommandStyle.length -gt 0) { $cmdStyle = $CommandStyle }
    if ($cmdStyle.length -eq 0)     { $cmdStyle ="Windows" }
    if ($cmdStyle -eq "Unix")       { $trnTable.boolean = "string" }
    # ==========================================================================================================================
    #   Get a list of all available api's and convert them into regular Powershell functions. Including embedded help!
    # --------------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Collecting api function details......"
    if (!$Silent) { Write-Host "Welcome to psCloudstack V2.1.2" -NoNewLine }
    $laRSP = (Invoke-CSApiCall listApis -Format XML -Verbose:$false).listapisresponse
    if ($laRSP.success -eq "false") { return $laRSP }
    if (($apiVersion -ne $laRSP.'cloud-stack-version') -or ($apiCount -ne $laRSP.Count)) { Update-ApiInfo -apiVersion $laRSP."cloud-stack-version" -apiCount $laRSP.Count }
    if (!$Silent) { Write-Host " - Generating $($laRSP.Count) api functions for you" }
    Write-Verbose "Generating $($laRSP.Count) api functions...... ($cmdStyle style)"
    $apiCnt = 0
    foreach ($api in $laRSP.api)
    {
        # -------------------------------------------------------------------------------
        #  Get all possible api parameters and create a sorted list
        # -------------------------------------------------------------------------------
        $apiName = $api.name; $prmList = ""; $apiCnt += 1
        [string[]]$prmNames = $api.params.name|sort -unique
        $prmCount = $prmNames.Count
        # -------------------------------------------------------------------------------
        #  Get all possible api responses and create a sorted list. With only 2 response
        #  values (displaytext & success) the api call result will be a boolean
        # -------------------------------------------------------------------------------
        [string[]]$rspNames = $api.response.name|sort -unique
        $rspCount = $rspNames.Count
        $rspBool = (($rspCount -eq 2) -and $rspNames.Contains("displaytext") -and $rspNames.Contains("success"))
        # -------------------------------------------------------------------------------
        #  Is it an asynchronous api?
        # -------------------------------------------------------------------------------
        $asyncApi = $($api.isasync) -eq "true"
        # -------------------------------------------------------------------------------
        #  Build a sorted (and pretty formatted) list of related api's 
        # -------------------------------------------------------------------------------
        $linkApi = "None"
        if ($api.related.length -gt 0) { $linkApi  = ($api.related.Split(",")|sort -unique) -join "`r`n- " }
        $asyncMark = ""; if ($asyncApi) { $asyncMark = "(A)" }
        Write-Verbose (" {0:0##} - $apiName {1}" -f $apiCnt,$asyncMark)
        # ----------------------------------------------------------------------------------------------------------------------
        #  Start the build of the api function code. Define the function as global so it will 'survive' the script ending
        #  The function code is build as a Here-String for which some parts will be generated dynamically
        # ----------------------------------------------------------------------------------------------------------------------
        $apiFunction =
@"
function global:$apiName {
<# 
 .Synopsis
  $($api.description)
 .Description
  $($api.description)
    Asynch: $($api.isasync)
    
"@
        # ----------------------------------------------------------------------------------------------------------------------
        #  Build a neatly formatted list of parameters, make sure mandatory and type settings are correct
        # ----------------------------------------------------------------------------------------------------------------------
        foreach ($prm in ($api.params|sort name -unique))
        {
            $apiFunction += " .Parameter {0}`r`n     {1}`r`n" -f $prm.name,$prm.description
            $prmRequired = ($prm.required -eq "true"); $prmType = $trnTable["$($prm.type)"]
            $prmList += ("[Parameter(Mandatory=`${0})][{1}]`${2},`r`n      " -f $prmRequired,$prmType,$prm.name)
        }
        if ($asyncApi)
        {
            $apiFunction += " .Parameter NoWait`r`n     Do not wait for the job to complete. Return the result(s) immediate after starting the job`r`n"
            $prmList += "[Parameter(Mandatory=`$false,ParameterSetName='NoWait')][switch]`$NoWait,`r`n      "
            $apiFunction += " .Parameter Wait`r`n     Wait xxx seconds for the job to complete before returning results. (Default: Wait for ever)`r`n"
            $prmList += "[Parameter(Mandatory=`$false,ParameterSetName='Wait')][int32]`$Wait=-1,`r`n      "
        }
        if ($prmList -ne "") { $prmList = $prmList.TrimEnd(",`r`n      ") }
        $apiFunction += "`r`n .Outputs`r`n  System.Object`r`n"
        foreach ($rsp in $api.response|sort name) { if ($rsp) { $apiFunction += "`r`n  - {0,-25}{1}" -f $rsp.name,$rsp.description } }
        $apiFunction +=
@"

 .Notes
    psCloudstack   : V2.1.2
    Function Name  : $apiName
    Author         : Hans van Veen
    Requires       : PowerShell V2
 
 .Link
    Related functions (aka API calls) are:
    - $linkApi

#>
[CmdletBinding(PositionalBinding=`$false, DefaultParameterSetName="$apiName")] 
param($prmList)
    # ======================================================================================================================
    #  Local & Global variables
    # ----------------------------------------------------------------------------------------------------------------------
    [string[]]`$Parameters = `$null
    `$doDebug   = (`$DebugPreference   -eq "Continue")
    `$doVerbose = (`$VerbosePreference -eq "Continue")
    `$boundParameters = `$PSBoundParameters
    `$skipList = "Debug","ErrorAction","ErrorVariable","OutVariable","OutBuffer","PipelineVariable","Verbose","WarningAction","WarningVariable","Wait","NoWait"
    `$asyncApi = "$asyncApi" -eq "True"
    # ======================================================================================================================
    #  Verify build and current config. Reload psCloudstack if there is no match
    # ----------------------------------------------------------------------------------------------------------------------
    `$buildKey = "$($Connect.Api)"
    `$currentCfg = Get-CSConfig -ShowKeys
    if (`$buildKey -ne `$currentCfg.Api)
    {
        Write-Warning "Invalid config detected, reloading psCloudstack...."
        Import-Module -Name  psCloudstack -Force -ea SilentlyContinue
        Connect-CSManager
        Return
    }
    # ======================================================================================================================
    #  Build the api call and issue it. Non-cloudstack parameters are skipped and list parameter values are joined
    # ----------------------------------------------------------------------------------------------------------------------
    foreach (`$prmName in `$boundParameters.Keys)
    {
        if (`$skipList.Contains(`$prmName)) { continue }
        `$prmValue = `$boundParameters["`$prmName"]
        [string[]]`$Parameters += "`$prmName=`$(`$prmValue -join ",")"
    }
    `$apiResponse = Invoke-CSApiCAll $apiName `$Parameters -Verbose:`$doVerbose -Debug:`$doDebug

"@
        # ----------------------------------------------------------------------------------------------------------------------
        #  Code section for asynchronous jobs
        # ----------------------------------------------------------------------------------------------------------------------
        if ($asyncApi)
        {
            $apiFunction +=
@"
    # ======================================================================================================================
    #  Asynchronous job: see whether we have to wait for completion, and if so.... do so.....
    #  Use the jobinstancetype to determine if there is a matching list function. If so use that to display the results
    # ----------------------------------------------------------------------------------------------------------------------
    `$jobId  = `$apiResponse.selectsinglenode("//jobid")."#text"
    Write-Verbose "Async job started with id: `$jobId"
    `$jobResult = (Invoke-CSApiCall queryAsyncJobResult jobid=`$jobId -Verbose:`$false -Debug:`$false).queryasyncjobresultresponse
    `$jobSts = `$jobResult.jobstatus
    `$instanceName = "list{0}*" -f `$jobResult.jobinstancetype
    `$functionName = (ls function:`$instanceName -name -ea SilentlyContinue)
    if (!`$NoWait)
    {
        Write-Host "Waiting for asynchronous job to complete"
        `$cntDown = `$Wait
        while ((`$cntDown -ne 0) -and (`$jobSts -eq 0))
        {
            Write-Host "." -NoNewLine; Start-Sleep -Sec 1
            `$jobResult = (Invoke-CSApiCall queryAsyncJobResult jobid=`$jobId -Verbose:`$false -Debug:`$false).queryasyncjobresultresponse
            `$jobSts = `$jobResult.jobstatus; `$cntDown -= 1
        }
        Write-Host ""
        if (`$cntDown -eq 0) { Write-Warning "Job wait timeout, job is still running" }
    }
    if (`$jobSts -eq 2)
    {
        `$resultCode = `$jobResult.jobresultcode
        `$errorCode = `$jobResult.jobresult.errorcode
        `$errorText = `$jobResult.jobresult.errortext
        `$errObject = New-Object -TypeName PSObject
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  completionStatus -Value `$false
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  apiName          -Value $apiName
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  displaytext      -Value `$errorText
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  errorcode        -Value `$errorCode
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  success          -Value `$resultCode
        Write-Warning "$apiName failed - Error `$errorCode, `$errorText"
        Write-Output `$errObject
        return
    }
    Write-Output `$jobResult
    if ((`$functionName.Count -eq 1)) { Write-Output (.`$functionName -id `$jobResult.jobinstanceId) }
    else { Write-Warning "Cannot determine related list function for $apiName" }
    return
}

"@
        # ----------------------------------------------------------------------------------------------------------------------
        #  Code section for synchronous jobs.
        # ----------------------------------------------------------------------------------------------------------------------
        }
        else
        {
            $apiFunction +=
@"
    # ======================================================================================================================
    #  Synchronous job: convert the api response to the output system.object
    #  Add a completionStatus boolean of our own to this object!
    # ----------------------------------------------------------------------------------------------------------------------
    `$Items = `$apiResponse.lastChild; `$itemCnt = `$Items.count
    `$stsText = `$Items.displaytext; `$errCode = `$Items.errorcode; `$stsCode = `$Items.success
    # ----------------------------------------------------------------------------------------------------------------------
    #  Check: is it an error response? If so set the completionStatus to false else process the returned data
    # ----------------------------------------------------------------------------------------------------------------------
    if ((`$stsText.Length -gt 0) -and (`$stsCode -eq "false"))
    {
        `$errObject = New-Object -TypeName PSObject
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  completionStatus -Value `$false
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  apiName          -Value $apiName
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  displaytext      -Value `$stsText
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  errorcode        -Value `$errCode
        `$errObject|Add-Member NoteProperty -TypeName psCloudstack.Error -Name  success          -Value `$stsCode
        Write-Output `$errObject
        return
    }
    # ----------------------------------------------------------------------------------------------------------------------
    #  Got a successful response, lets process the data
    # ----------------------------------------------------------------------------------------------------------------------
    else
    {
        if (!`$itemCnt) { if (!`$Items.success) { `$Items = `$Items.get_ChildNodes() }; `$itemCnt = 1 }
        else { `$Items = `$Items.get_ChildNodes().NextSibling }
        Write-Verbose "Received `$itemCnt response items"
        foreach (`$Item in `$Items)
        {
            if (`$Item -eq `$null) { Continue }
            `$apiObject  = New-Object -TypeName PSObject
            `$apiObject|Add-Member NoteProperty -TypeName psCloudstack.$apiName -Name completionStatus -Value `$true
            foreach (`$rspName in "$rspNames".split())
            {
                `$apiObject|Add-Member NoteProperty -TypeName psCloudstack.$apiName -Name `$rspName -Value `$Item.`$rspName
            }
            Write-Output `$apiObject
        }
        return
    }
}

"@
        }
    # ----------------------------------------------------------------------------------------------------------------------
    #  Function code is ready, use Invoke-Expression to 'activate' the function 
    # ----------------------------------------------------------------------------------------------------------------------
    iex $apiFunction
    }
}

############################################################################################################################
####                                      Internal-Only (Non-Exported) Functions                                        ####
############################################################################################################################
#  Update-ApiInfo
#    This is a non-exported function which is used to update the Api info in the active config file
############################################################################################################################
function Update-ApiInfo {
param([Parameter(Mandatory = $true)][string]$apiVersion,[Parameter(Mandatory = $true)][string]$apiCount)
    # ======================================================================================================================
    #  Open the active config file
    # ----------------------------------------------------------------------------------------------------------------------
    $ConfigFile = $env:CSCONFIGFILE
    if (($ConfigFile -eq "") -or !(Test-Path "$ConfigFile")) { throw "No psCloudstack configuration file found" }
    Write-Verbose "Update Api info using: $ConfigFile"
    [xml]$curCfg = gc "$ConfigFile"
    # ======================================================================================================================
    #  Get the api details and store them
    # ----------------------------------------------------------------------------------------------------------------------
    $curCfg.configuration.api.version = $apiVersion
    $curCfg.configuration.api.count   = $apiCount
    Write-Verbose "Updating the api details"
    $curCfg.Save($ConfigFile)
    # ----------------------------------------------------------------------------------------------------------------------
}
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

 .Inputs
  ConfigFile
      The path and name of a config file to store as %CSCONFIGFILE%.

 .Outputs
  None
    
 .Notes
    psCloudstack   : V1.2
    Function Name  : Set-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([parameter(Mandatory=$true)][string]$ConfigFile)
    $bndPrm = $PSCmdlet.MyInvocation.BoundParameters
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
  Gets the configuration and connection settings from the active configuration file.

 .Description
  This function gets the configuration and connection settings from the active config file. This config file, which has
  been created with Initialize-CSConfig and/or set to active with Set-CSConfig, contains the required connection info for
  connecting to the Cloudstack Management server, either via the authenticated or unauthenticated port.

  If no configuration file is specified, the value of %CSCONFIGFILE% will be used. And if that environment varaiable does
  not exist %LOCALAPPDATA%\psCloudstack.config will be used.
  
 .Inputs
  ConfigFile
      The path and name of a config file which contains the configuration and connection settings.
      
  ShowKeys
      Show the API & Secret key in the output object.

 .Outputs
  System.Object
      A System.Object which contains all collected settings.
      - File             The active configurationfile
      - Server           The server to connect to
      - UseSSL           Use https for connecting
      - SecurePort       The secure port number
      - UnsecurePort     The unsecure port number
      - Api              The user api key (when requested)
      - Key              The user secret key (when requested)
      - Version          The LAST used cloudstack version!
      - Count            The number of available api calls in that version
    
 .Notes
    psCloudstack   : V1.2
    Function Name  : Get-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([string]$ConfigFile,[switch]$ShowKeys)
    $bndPrm = $PSCmdlet.MyInvocation.BoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Local & Global variables
    # ----------------------------------------------------------------------------------------------------------------------
    $csObject  = New-Object -TypeName System.Object
    $addNote = {param($n,$v);Add-Member -InputObject $csObject -MemberType NoteProperty -Name $n -Value $v -Force}
    # ======================================================================================================================
    #  Verifying configuration file and if found make it the active one
    # ----------------------------------------------------------------------------------------------------------------------
    if  ($ConfigFile -eq "") { $ConfigFile = $env:CSCONFIGFILE }
    if  ($ConfigFile -eq "") { $ConfigFile = "{0}\psCloudstack.config" -f $env:LocalAppData }
    if (($ConfigFile -eq "") -or !(Test-Path "$ConfigFile")) { throw "No psCloudstack configuration file found" }
    Write-Verbose "Using config: $ConfigFile"
    Set-CSConfig "$ConfigFile"
    # ======================================================================================================================
    #  Read the config file connect details and store them in the connect object
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Reading psCloudstack config file"
    [xml]$cfg = gc "$ConfigFile"
    $Connect = $cfg.configuration.connect
    $Api = $cfg.configuration.api
    .$addNote File         $ConfigFile
    .$addNote Server       $Connect.server.address
    .$addNote UseSSL      ($Connect.server.usessl -eq "true")
    .$addNote SecurePort   $Connect.server.secureport
    .$addNote UnsecurePort $Connect.server.unsecureport
    if ($ShowKeys)
    {
        .$addNote Api      $Connect.authentication.api
        .$addNote Key      $Connect.authentication.key
    }
    .$addNote Version      $Api.version
    .$addNote Count        $Api.count
    # ======================================================================================================================
    #  All connection details are collected, write the object
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Output $csObject
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
  
 .Inputs
  Server (required)
      The name or IP address of the Cloudstack management server. This is a required parameter.
      If a config file is updated the server IP address will be used to verify the correctness
      of the existing content

  SecurePort
      The API secure port number. (default: 8080)

  UnecurePort
      The API unsecure port number. (default: 8096)
      
  Apikey
      The users apikey. This key will be, in combination with the users secret key, be converted
      to a single hash value. This hash value will be stored in the config file.
      
  Secret
      The users secret key. This key will be, in combination with the users api key, be converted
      to a single hash value. This hash value will be stored in the config file.

  UseSSL
      Use https when connecting to the Cloudstack management server. Only used when requesting access
      via the secured port.

  Config
      The path and name of a config file to which the input information is written.
      By default %LOCALAPPDATA%\psCloudstack.config will be used, but a different file can be specified.
      The full filespec is also saved in %CSCONFIGFILE% and is used by Get-CSConfig in case the
      default file cannot be found.

 .Outputs
  None
    
 .Notes
    psCloudstack   : V1.2
    Function Name  : Initialize-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V2

  .Example
   # Create/Update the content of the default config file

   C:\PS> Initialize-CSConfig -Server www.xxx.yyy.zzz -Api xxxxxxx -Secret yyyyyyyyy

#>
[CmdletBinding()]
param([parameter(Mandatory=$true)][string]$Server,
      [int]$SecurePort=8080,
      [int]$UnsecurePort=8096,
      [string]$Apikey,
      [string]$Secret,
      [switch]$UseSSL,
      [string]$ConfigFile=("{0}\psCloudstack.config" -f $env:LocalAppData))
    $bndPrm = $PSCmdlet.MyInvocation.BoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Local & Global variables
    # ----------------------------------------------------------------------------------------------------------------------
    $doUpdate = $false; $doUseSSL = ($UseSSL -and $true).ToString().ToLower()
    $sysPing = New-Object System.Net.NetworkInformation.Ping
    $ipRegex = "^\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b$"
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
    #  Check the config file. If it exists update the connection information therein
    # ----------------------------------------------------------------------------------------------------------------------
    if (Test-Path "$ConfigFile")
    {
        Write-Verbose "Update existing Cloudstack config file"
        [xml]$cfg = gc "$ConfigFile"
        $Connect = $cfg.configuration.connect
        $cfgServer = $Connect.server.address
        $cfgUseSSL = $Connect.server.usessl
        $cfgSPort  = $Connect.server.secureport
        $cfgUPort  = $Connect.server.unsecureport
        $cfgApi    = $Connect.authentication.api
        $cfgKey    = $Connect.authentication.key
        if (!$Apikey) { $Apikey = $cfgApi }
        if (!$Secret) { $Secret = $cfgKey }
    }
    else
    # ======================================================================================================================
    #  No existing file, create a new empty one
    # ----------------------------------------------------------------------------------------------------------------------
    {
        Write-Verbose "Create new Cloudstack config file"
        if (!$Apikey -or !$Secret) { throw "No connect credentials supplied" }
        [xml]$cfg = '<?xml version="1.0" encoding="utf-8"?>
                     <configuration>
                       <connect>
                         <server address="" secureport="" unsecureport="" usessl="" />
                         <authentication api="" key=""/>
                       </connect>
                       <api version="" count="" />
                     </configuration>'
        # ------------------------------------------------------------------------------------------------------------------
        #  Convert the 'string' above to an xml document and set its content
        # ------------------------------------------------------------------------------------------------------------------
        $Connect = $cfg.Configuration.Connect
    }
    # ----------------------------------------------------------------------------------------------------------------------
    #  Update the info and save the file
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect.server.address = $Server
    if ($cfgUseSSL -ne $doUseSSL) { $Connect.server.usessl = $doUseSSL }
    if ($cfgSPort -ne $SecurePort.ToString()) { $Connect.server.secureport = $SecurePort.ToString() }
    if ($cfgUPort -ne $UnsecurePort.ToString()) { $Connect.server.unsecureport = $UnsecurePort.ToString() }
    if ($cfgApi -ne $Apikey) { $Connect.authentication.api = $Apikey }
    if ($cfgKey -ne $Secret) { $Connect.authentication.key = $Secret }
    rv Apikey; rv Secret
    Write-Verbose "Update connection configuration"
    $cfg.Save($ConfigFile)
    # ======================================================================================================================
    #  Now for the exiting stuff. Get a complete list of api's from the server and if required update the config file
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Verifying Cloudstack api details"
    $api = $cfg.Configuration.api
    [xml]$apiList = (Invoke-CSApiCall listApis -Format XML -UseUnsecure)
    $apiVersion =  $apiList.listapisresponse.'cloud-stack-version'
    if ($api.Version -ne $apiVersion) { $api.Version = $apiVersion }
    $apiCount   = $apiList.listapisresponse.count
    if ($api.Count -ne $apiCount) { $api.Count = $apiCount }
    Write-Verbose "Updating the api details"
    $cfg.Save($ConfigFile)
    # ======================================================================================================================
    #  New/Updated config file is ready to use, activate it......
    # ----------------------------------------------------------------------------------------------------------------------
    Set-CSConfig "$ConfigFile"
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

 .Inputs
  Command
      The api command to issue.

  Parameters
      A comma-separate list of additional api call parameters and values

  Format
      Specifies the reponse output format. By default XML output is returned, the other option is JSON

  Server
      The name or IP address of the Cloudstack management server. Using this parameter will override
      value from the the config 

  SecurePort
      The API secure port number. Using this parameter will override value from the the config

  UnecurePort
      The API unsecure port number. Using this parameter will override value from the the config

  Apikey
      The users apikey.  Using this parameter will override value from the the config 
      
  Secret
      The users secret key.  Using this parameter will override value from the the config 

  UseSSL
      Use https when connecting to the Cloudstack management server.
      Only used when requesting access via the secured port.

  UseUnsecure
      When this switch is specified the api call will be directed to the unsecure port


 .Outputs
  XML or JSON object
   An object which contains all content output returned by the api call in the requested format
    
 .Notes
    psCloudstack   : V1.2
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
    $bndPrm = $PSCmdlet.MyInvocation.BoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ======================================================================================================================
    #  Trap all errors and return them in a fashionable way...
    # ----------------------------------------------------------------------------------------------------------------------
    trap
    {
        $errMsg = "API Call Error: $($iwr.Message)"
        Write-Host  $errMsg -f DarkBlue -b Yellow;
        return [xml]"<error><message>$errMsg</message></error>"
    }
    # ======================================================================================================================
    #  Local variables and definitions.
    # ----------------------------------------------------------------------------------------------------------------------
    [void][System.Reflection.Assembly]::LoadWithpartialname("System.Web")
    $crypt = New-Object System.Security.Cryptography.HMACSHA1
    # ======================================================================================================================
    #  Get the connection details from the config file. Then see whether there are overrides....
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect = Get-CSConfig -ShowKeys
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
    #            has to stay! Assume the name to be compliant and only convert the value. Pittfall #2: UrlEncode
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
        $Response = Invoke-WebRequest "$csUrl" -ErrorVariable iwr
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
        $Response = Invoke-WebRequest "$csUrl" -ErrorVariable iwr
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

  When running this function with -Verbose the async api functions will be marked with a (*).
  
 .Inputs
  None

 .Outputs
  All available Cloudstack api calls as PowerShell functions
    
 .Notes
    psCloudstack   : V1.2
    Function Name  : Connect-CSManager
    Author         : Hans van Veen
    Requires       : PowerShell V2

#>
[CmdletBinding()]
param([switch]$Silent)
    $bndPrm = $PSCmdlet.MyInvocation.BoundParameters
    $doVerbose = $bndPrm.Verbose; if ($doVerbose) { $VerbosePreference = "Continue" } else { $VerbosePreference = "SilentlyContinue" }
    $doDebug   = $bndPrm.Debug;   if ($doDebug)   { $DebugPreference   = "Continue" } else { $DebugPreference   = "SilentlyContinue" }
    # ==========================================================================================================================
    #   The api parameter types differ in name from the Powershell types. Create a translation table to deal with this
    #   Beware: The unix date format yyyy-MM-dd has no counterpart in Powershell, therefore its replaced by type string
    # --------------------------------------------------------------------------------------------------------------------------
    $trnTable  = @{ "boolean" = "switch" ; "date"  = "string" ; "integer" = "int32"  ; "list" = "string[]" ; "long"   = "int64" ;
                    "map"     = "string" ; "short" = "int16"  ; "string"  = "string" ; "uuid" = "string"   ; "tzdate" = "string" }
    # ==========================================================================================================================
    #   Get a list of all available api's and convert them into regular Powershell functions. Including embedded help!
    # --------------------------------------------------------------------------------------------------------------------------
    if (!$Silent) { Write-Host "Welcome to psCloudstack V1.2" -NoNewLine }
    Write-Verbose "Collecting api function details......"
    $Connect = Get-CSConfig -ShowKeys
    $apiVersion = $Connect.Version
    $laRSP = (Invoke-CSApiCall listApis).listapisresponse
    if ($apiVersion -ne $laRSP.'cloud-stack-version') { Write-Warning "Cloudstack version mismatch. Stored: $apiversion, Active: $($laRSP.'cloud-stack-version')" }
    if (!$Silent) { Write-Host " - Generating $($laRSP.Count) api functions for you" }
    Write-Verbose "Generating $($laRSP.Count) api functions......"
    $apiCnt = 0
    foreach ($api in $laRSP.api)
    {
        $apiName = $api.name; $prmList = ""; $apiCnt += 1
        [string[]]$prmNames = $api.params.name|sort -unique
        $prmCount = $prmNames.Count
        [string[]]$rspNames = $api.response.name|sort -unique
        $rspCount = $rspNames.Count
        $asyncApi = $($api.isasync) -eq "true"
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
        #  Upper-case the 1st character of each parameter (just for the looks) and do not forget to revert this
        #  before building the api call.
        # ----------------------------------------------------------------------------------------------------------------------
        foreach ($prm in ($api.params|sort name -unique))
        {
            $apiFunction += " .Parameter {0}`r`n     {1}`r`n" -f $prm.name,$prm.description
            $prmName = ($prm.name).Replace(($prm.name[0]),($prm.name[0].ToString().ToUpper()))
            $prmRequired = ($prm.required -eq "true"); $prmType = $trnTable["$($prm.type)"]
            $prmList += ("[Parameter(Mandatory=`${0})][{1}]`${2},`r`n      " -f $prmRequired,$prmType,$prmName)
        }
        if ($asyncApi)
        {
            $apiFunction += " .Parameter NoWait`r`n     Do not wait for the job to complete. Return the jobid immediate after starting the job`r`n"
            $apiFunction += " .Parameter Wait`r`n     Wait for the job to complete (Default: Wait for ever). If the job does not complete within the specified time return the jobid, else return the actual job completion details`r`n"
            $prmList += "[Parameter(Mandatory=`$false)][switch]`$NoWait,`r`n      [Parameter(Mandatory=`$false)][int32]`$Wait,`r`n      "
        }
        if ($prmList -ne "") { $prmList = $prmList.TrimEnd(",`r`n      ") }
        $apiFunction += "`r`n .Outputs`r`n  System.Object      The returned object contains all api information stored as NoteProperties`r`n"
        foreach ($rsp in $api.response|sort name) { $apiFunction += "     {0,-25}{1}`r`n" -f $rsp.name,$rsp.description }
        $apiFunction +=
@"

 .Notes
    psCloudstack   : V1.2
    Function Name  : $apiName
    Author         : Hans van Veen
    Requires       : PowerShell V2
 
 .Link
    Related functions (aka API calls) are:
    $($api.related)

#>
[CmdletBinding(PositionalBinding=`$false)]
param($prmList)
    # ======================================================================================================================
    #  Local & Global variables
    # ----------------------------------------------------------------------------------------------------------------------
    [string[]]`$Parameters = `$null
    `$doDebug   = (`$DebugPreference   -eq "Continue")
    `$doVerbose = (`$VerbosePreference -eq "Continue")
    `$boundParameters = `$PSCmdlet.MyInvocation.BoundParameters
    `$skipList = "Debug","ErrorAction","ErrorVariable","OutVariable","OutBuffer","PipelineVariable","Verbose","WarningAction","WarningVariable"
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
    #  Build the api call and issue it. During the function build all parameter names got capitalized, revert this
    #  to prevent "unable to verify user credentials and/or request signature" errors. Common parameters are skipped!
    # ----------------------------------------------------------------------------------------------------------------------
    foreach (`$prmName in `$boundParameters.Keys)
    {
        if (`$skipList.Contains(`$prmName)) { continue }
        `$prmValue = `$boundParameters["`$prmName"]
        `$prmType  = (`$boundParameters["`$prmName"]).GetType().Name
        `$prmName  = `$prmName.ToLower()
        switch (`$prmType)
        {
            "string"            { [string[]]`$Parameters += "`$prmName=`$prmValue" ; break }
            "string[]"          { [string[]]`$Parameters += "`$prmName=`$(`$prmValue -join ",")" ; break }
            "Int16"             { [string[]]`$Parameters += "`$prmName=`$prmValue" ; break }
            "Int32"             { [string[]]`$Parameters += "`$prmName=`$prmValue" ; break }
            "Int64"             { [string[]]`$Parameters += "`$prmName=`$prmValue" ; break }
            "Boolean"           { [string[]]`$Parameters += "`$prmName=`$prmValue" ; break }
            "SwitchParameter"   { [string[]]`$Parameters += "`$prmName=`$prmValue" ; break }
            default             { Write-Warning "Cannot process [`$prmType]`$prmName" ; break }
        }
    }
    `$apiResponse = Invoke-CSApiCAll $apiName `$Parameters -Verbose:`$doVerbose -Debug:`$doDebug
    # ======================================================================================================================
    #  Take the api response and assign the returned values to the output system.object
    # ----------------------------------------------------------------------------------------------------------------------
    `$rspName    = `$apiResponse.get_LastChild().get_SchemaInfo().localname
    if (`$apiResponse.`$rspName.get_LastChild() -eq `$null) { Write-Output `$null; return }
    `$nodeName   = `$apiResponse.`$rspName.get_LastChild().get_SchemaInfo().localname
    `$rspCount   = `$apiResponse.`$rspName.Count
    [array]`$rsp = `$apiResponse.`$rspName.`$nodeName
    try { `$rspType = `$rsp.getTypeCode() }
    catch
    {
        `$rspType = `$null; if (!`$rspCount) { `$rspCount = 1 }
        for (`$i=0;`$i -lt `$rspCount;`$i++)
        {
            `$apiObject  = New-Object -TypeName System.Object
            `$apiNote = {param(`$n,`$v);Add-Member -InputObject `$apiObject -MemberType NoteProperty -Name `$n -Value `$v -Force}
            foreach (`$rspName in "$rspNames".split())
            {
                try { `$val = `$rsp[`$i].`$rspName }
                catch [System.Management.Automation.ItemNotFoundException] { `$val = `$null }
                if (`$val -ne `$null) { .`$apiNote `$rspName `$val }
            }
            write-output `$apiObject
        }
    }
    if (`$rspType -ne `$null)
    {
        `$apiObject  = New-Object -TypeName System.Object
        Add-Member -InputObject `$apiObject -MemberType NoteProperty -Name `$nodeName -Value `$rsp[0] -Force
        write-output `$apiObject
    }
}

"@
    # ----------------------------------------------------------------------------------------------------------------------
    #  Function code is ready, use Invoke-Expression to 'activate' the function 
    # ----------------------------------------------------------------------------------------------------------------------
    iex $apiFunction
    #if ($apiCnt -eq 2) {  Write-Output $apiFunction; break }
    }
}

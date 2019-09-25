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
$pscsVersion         = "3.4.1"
$defaultZone         = "Default"
$defaultConfigFile   = "{0}\psCloudstack.config" -f $env:LocalAppData
$defaultUnsecurePort = 80
$defaultSecurePort   = 443
############################################################################################################################
#  Set-CSConfig
#    Updates parts of a zone connection configuration
############################################################################################################################
function Set-CSConfig
{
<# 
 .Synopsis
    Updates parts of a zone connection configuration

 .Description
    This function is used to modify connection configuration information of a zone connection.

 .Parameter Zone
    A reference name which will identify the zone connection data.

 .Parameter NewName
    A new reference name which will identify the zone connection data.
    A warning will be generated in case of a duplicate zone name

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

 .Parameter ConfigFile
    The path and name of a config file to which the input information is written.
    By default $Env:LocalAppData\psCloudstack.config will be used, but a different file can be specified.

 .Outputs
    None

    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Set-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([parameter(Mandatory = $true)][string]$Zone,
      [parameter(Mandatory = $false)][string]$NewName,
      [parameter(Mandatory = $false)][string]$Server,
      [Parameter(Mandatory = $false)][int]$SecurePort = $defaultSecurePort,
      [Parameter(Mandatory = $false)][int]$UnsecurePort = $defaultUnsecurePort,
      [Parameter(Mandatory = $false)][string]$Apikey,
      [Parameter(Mandatory = $false)][string]$Secret,
      [Parameter(Mandatory = $false)][switch]$UseSSL,
      [Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Verifying configuration file and if found make it the active one
    # ----------------------------------------------------------------------------------------------------------------------
    if (($ConfigFile -eq "") -or !(Test-Path "$ConfigFile")) { Write-Error "No psCloudstack configuration file found"; Break }
    # ======================================================================================================================
    #  Read the config file connect details and isolate the data we need/want
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Reading psCloudstack config file"
    [xml]$curCfg = gc "$ConfigFile"
    $dataSet = $curCfg.configuration.connect|? Zone -eq $Zone
    if (!$dataSet -and ($Zone -eq $defaultZone)) { $dataSet = $curCfg.configuration.connect[0] }
    if (!$dataSet) { Write-Warning "No such config dataset `"$Zone`""; break }
    # ======================================================================================================================
    #  Update the requested fields and save the result
    # ----------------------------------------------------------------------------------------------------------------------
    if ($bndPrm.NewName -ne $null)      { $dataSet.zone = $NewName }
    if ($bndPrm.Server -ne $null)       { $dataSet.server.address = $Server }
    if ($bndPrm.SecurePort -ne $null)   { $dataSet.server.secureport = $SecurePort }
    if ($bndPrm.UnsecurePort -ne $null) { $dataSet.server.unsecureport = $UnsecurePort }
    if ($bndPrm.Apikey -ne $null)       { $dataSet.authentication.api = $Apikey }
    if ($bndPrm.Secret -ne $null)       { $dataSet.authentication.key = $Secret }
    if ($bndPrm.UseSSL -ne $null)       { $dataSet.server.usessl = $UseSSL.ToString() }
    # ======================================================================================================================
    #  All has been updated, save the result and exit
    # ----------------------------------------------------------------------------------------------------------------------
    $curCfg.Save($ConfigFile)
    Write-Verbose "psCloudstack config has been updated"
}

############################################################################################################################
#  Get-CSConfig
#    Reads the configuration for the Cloudstack Management server and returns it as a system.object
############################################################################################################################
function Get-CSConfig
{
<# 
 .Synopsis
    Get the configuration and connection settings from the active or requested configuration file.

 .Description
    This function gets one ore more connection sets from the configuration file. This configuration file
    contains the required connection info for connecting to a Cloudstack Management server, either via the
    authenticated or unauthenticated port.

    If no configuration file is specified, $Env:LocalAppData\psCloudstack.config will be used.

 .Parameter Zone
    A reference name which will identify the zone connection data. If no name is specified, all data
    will be returned.
  
 .Parameter ConfigFile
    The path and name of a config file which contains the configuration and connection settings.

 .Parameter ShowKeys
    Show the API & Secret key in the output object.

 .Outputs
  psCloudstack.Config Object
    A psCloudstack.Config System.Object which contains all collected settings.
    - File             The active configurationfile
    - Zone             The reference name of the zone connection
    - Server           The server to connect to
    - UseSSL           Use https for connecting
    - SecurePort       The secure port number
    - UnsecurePort     The unsecure port number
    - Api              The user api key (when requested)
    - Key              The user secret key (when requested)
    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Get-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([parameter(Mandatory = $false)][string[]]$Zone = $defaultZone,
      [Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile,
      [parameter(Mandatory = $false)][switch]$All,
      [parameter(Mandatory = $false)][switch]$ShowKeys)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Verifying configuration file and if found make it the active one
    # ----------------------------------------------------------------------------------------------------------------------
    if (($ConfigFile -eq "") -or !(Test-Path "$ConfigFile")) { Write-Error "No psCloudstack configuration file found"; Break }
    # ======================================================================================================================
    #  Read the config file connect details and isolate the data we need/want
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Reading psCloudstack config file"
    [xml]$curCfg = gc "$ConfigFile"
    [array]$curConnect = $curCfg.configuration.connect
    if ($All) { $Zone = $curConnect|%{ $_.Zone } }
    foreach ($getZone in $Zone)
    {
        $dataSet = $curConnect|? Zone -eq $getZone
        if (!$dataSet -and ($getZone -eq $defaultZone)) { $dataSet = $curConnect[0] }
        if (!$dataSet) { Write-Warning "Zone `"$getZone`" dataset not found"; continue }
        # ==================================================================================================================
        #  Per named dataset, store all requested details in the connect object and send it down the pipeline
        # ------------------------------------------------------------------------------------------------------------------
        $cfgObject = New-Object -TypeName PSObject
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Zone         -Value $dataSet.zone
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Server       -Value $dataSet.server.address
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name UseSSL       -Value ($dataSet.server.usessl -eq "true")
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name SecurePort   -Value $dataSet.server.secureport
        $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name UnsecurePort -Value $dataSet.server.unsecureport
        if ($ShowKeys)
        {
            $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Api      -Value $dataSet.authentication.api
            $cfgObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Key      -Value $dataSet.authentication.key
        }
        # ==================================================================================================================
        #  All connection details are collected, write the object
        # ------------------------------------------------------------------------------------------------------------------
        Write-Output $cfgObject
    }
}

############################################################################################################################
#  Add-CSConfig
#    Adds connection configuration information to the configuration file
############################################################################################################################
function Add-CSConfig
{
<# 
 .Synopsis
    Adds connection configuration information to the configuration file

 .Description
    This function is used to add connection configuration information to the configuration file.

 .Parameter Zone
    A reference name which will identify the zone connection data.
    A warning will be generated in case of a duplicate zone name

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

 .Parameter ConfigFile
    The path and name of a config file to which the input information is written.
    By default $Env:LocalAppData\psCloudstack.config will be used, but a different file can be specified.

 .Outputs
    None
    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Add-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V3

  .Example
    # Create/Update the content of the default config file
    C:\PS> Add-CSConfig -Server www.xxx.yyy.zzz -Api xxxxxxx -Secret yyyyyyyyy

#>
[CmdletBinding()]
param([parameter(Mandatory = $false)][string]$Zone = $defaultZone,
      [parameter(Mandatory = $true)][string]$Server,
      [Parameter(Mandatory = $false)][int]$SecurePort = $defaultSecurePort,
      [Parameter(Mandatory = $false)][int]$UnsecurePort = $defaultUnsecurePort,
      [Parameter(Mandatory = $true)][string]$Apikey,
      [Parameter(Mandatory = $true)][string]$Secret,
      [Parameter(Mandatory = $false)][switch]$UseSSL = "true",
      [Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Check the config file. If it exists update it with the information
    # ----------------------------------------------------------------------------------------------------------------------
    if (Test-Path "$ConfigFile")
    {
        [xml]$curCfg = gc "$ConfigFile"
        if ($curCfg.configuration.connect|? Zone -eq $Zone) { Write-Warning "Configuration data for $Zone allready present, exiting...."; break }
        Write-Verbose "Update existing Cloudstack config file"
    }
    else
    {
        Write-Verbose "Creating new Cloudstack config file"
        [xml]$curCfg = New-CSConfig
    }
    # ======================================================================================================================
    # Get the command line config settings.
    # ----------------------------------------------------------------------------------------------------------------------
    [xml]$newCfg = "<?xml version=`"1.0`" encoding=`"utf-8`"?>
                    <configuration version=`"3.0`">
                      <connect zone=`"$Zone`">
                        <server address=`"$Server`" secureport=`"$SecurePort`" unsecureport=`"$UnsecurePort`" usessl=`"$UseSSL`"/>
                        <authentication api=`"$Apikey`" key=`"$Secret`"/>
                      </connect>
                    </configuration>"
    # ======================================================================================================================
    #  Append the new config settings to the existing config and save it.
    # ----------------------------------------------------------------------------------------------------------------------
    Foreach ($Node in $newCfg.DocumentElement.ChildNodes) { $res = $curCfg.DocumentElement.AppendChild($curCfg.ImportNode($Node, $true)) }
    $curCfg.Save($ConfigFile)
    Write-Verbose "psCloudstack config has been updated"
    # ----------------------------------------------------------------------------------------------------------------------
}


############################################################################################################################
#  Remove-CSConfig
#    Removes a named connection dataset from the configuration file
############################################################################################################################
function Remove-CSConfig
{
<# 
 .Synopsis
    Remove connection settings from a psCloudstack configuration file.

 .Description
    This function removes an existing connection dataset from a psCloudstack configuration file.

 .Parameter Zone
    A reference name which will identify the (zone) connection data. The function will terminate when no name is specified.
  
 .Parameter ConfigFile
    The path and name of a config file which contains the configuration and connection settings.

 .Outputs
    None
    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Remove-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([parameter(Mandatory=$true)][string[]]$Zone,
      [Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Verifying configuration file and if found make it the active one
    # ----------------------------------------------------------------------------------------------------------------------
    if (($ConfigFile -eq "") -or !(Test-Path "$ConfigFile")) { Write-Error "No psCloudstack configuration file found"; Break }
    # ======================================================================================================================
    #  Read the config file connect details and isolate the data we need/want
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Reading psCloudstack config file"
    [xml]$curCfg = gc "$ConfigFile"
    foreach ($rmvZone in $Zone)
    {
        $dataSet = $curCfg.configuration.connect|? Zone -eq $rmvZone
        if (!$dataSet) { Write-Warning "No such config dataset `"$rmvZone`""; continue }
        # ==================================================================================================================
        #  Remove the dataset from the config set and save the resulting set
        # ------------------------------------------------------------------------------------------------------------------
        Write-Verbose "Removing `"$rmvZone`" from the psCloudstack config file"
        $remCfg = $curCfg.configuration.RemoveChild($dataSet)
    }
    $curCfg.Save($ConfigFile)
    Write-Verbose "psCloudstack config has been updated"
}

############################################################################################################################
#  Convert-CSConfig
#    Creates or updates the connection configuration for the Cloudstack Management server and api calls to V3
#    This configuration is used by Connect-CSServer to establish a first connection and to verify the api status
############################################################################################################################
function Convert-CSConfig
{
<# 
 .Synopsis
    Converts a pre-V3 config file to a V3 config file

 .Description
    As of psCloudstack V3 there is only one configuration file: $Env:LOCALAPPDATA\psCloudstack.config
    (%LOCALAPPDATA%\psCloudstack.config) Pre-V3 configuration files can be converted to the V3 file
    format using the Convert-CSConfig function. Without specifying a source file and configuration
    name the current psCloudstack.config file will be read, converted and updated.
    This connection configuration will be named "Default"

    Specifying another configuration file will read, converted and appended its data to the (new)
    default configuration file. If no name is specified, "Default" will be used, but if this name
    already exists in the configuration file, the name will be appended with a "+" sign.

 .Parameter ConfigFile
    The path and name of an existing configuration file from which the information is read.

 .Parameter Zone
    A reference name which will identify the converted (zone) connection data. The name will be used by
    Connect-CSManager to load and use the required configuration. When the name already exists in
    the default configuration file, the name will be appended with a "+" sign.

 .Outputs
    None
    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Convert-CSConfig
    Author         : Hans van Veen
    Requires       : PowerShell V3

  .Example
    # Update the content of the default config file with converted pre-V3 data

    C:\PS> Convert-CSConfig -Conf C:\Users\......\AppData\Local\psCloudstack.config -Zone "......"

#>
[CmdletBinding()]
param([Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile,
      [Parameter(Mandatory = $false)][string]$Zone = $defaultZone)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Convert the configuration file
    # ----------------------------------------------------------------------------------------------------------------------
    if (!(Test-Path "$ConfigFile")) { Write-Error "Configuration file `"$ConfigFile`" not found"; Break }
    [xml]$curCfg = gc "$ConfigFile"
    if ($curCfg.configuration.version -lt 3.0)
    {
        Write-Verbose "Converting config file `"$ConfigFile`""
        $curCfg.configuration.version = "3.0"
        $curCfg.configuration.connect.SetAttribute("zone", $Zone)
        $apiCfg = $curCfg.configuration.RemoveChild($curCfg.SelectSingleNode('//api'))
    }
    # ======================================================================================================================
    #  If it is the default file than save it and exit
    # ----------------------------------------------------------------------------------------------------------------------
    if ($ConfigFile -eq $defaultConfigFile)
    {
        $curCfg.Save($defaultConfigFile)
        Write-Verbose "default psCloudstack config has been updated"
        break
    }
    # ======================================================================================================================
    #  Merge the converted content with that of the default file
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Merging psCloudstack config data"
    if (!(Test-Path "$defaultConfigFile"))
    {
        Write-Verbose "Creating new Cloudstack config file"
        [xml]$defCfg = New-CSConfig
    }
    else { [xml]$defCfg = gc "$defaultConfigFile" }
    if ($defCfg.configuration.version -lt 3.0)
    {
        Convert-CSConfig -ConfigFile "$defaultConfigFile"
        [xml]$defCfg = gc "$defaultConfigFile"
    }
    if ($defCfg.configuration.connect.zone -eq $curCfg.configuration.connect.zone)
    {
        $curCfg.configuration.connect.zone += "+"
        Write-Warning "Duplicate zone name found, using `"$($curCfg.configuration.connect.zone)`""
    }
    Foreach ($Node in $curCfg.DocumentElement.ChildNodes) { $res = $defCfg.DocumentElement.AppendChild($defCfg.ImportNode($Node, $true)) }
    $defCfg.Save($defaultConfigFile)
    Write-Verbose "default psCloudstack config has been updated"
}

############################################################################################################################
#  Start-CSConsoleSession
#    This function will start a Cloudstack (VM) console session for the specified server
############################################################################################################################
function Start-CSConsoleSession
{
<# 
 .Synopsis
    Start a Cloudstack (VM) console session

 .Description
    This function starts a console session for the specified server.

 .Parameter Server
    Name of the server to connect to.

 .Parameter Zone
    Name of the zone in which the server is hosted.
  
    Default: Default (or 1st zone in the config)

 .Parameter ConfigFile
    The path and name of a config file from which the session details will be read.
    By default $Env:LocalAppData\psCloudstack.config will be used, but a different file can be specified.

 .Outputs
    None

 .Example
    # Start a VM console for VMHost "Monkey" in Zone Zoo
    C:\PS> Start-CSConsoleSession -Server Monkey -Zone Zoo
    
  .Notes
    psCloudstack   : V3.4.1
    Function Name  : Start-CSConsoleSession
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([parameter(Mandatory = $true, Position = 0)][string]$Server,
      [parameter(Mandatory = $false)][string]$Zone = $defaultZone,
      [Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  If needed, create a new session object and load the config file details into it.
    # ----------------------------------------------------------------------------------------------------------------------
    if (!$global:pscsSessionObject)
    {
        New-pscsSessionObject
        Set-pscsSessionObject -csObject (Get-CSConfig -ShowKeys -Zone $Zone -ConfigFile $ConfigFile)
        Set-pscsSessionObject -ConfigFile $ConfigFile
    }
    # ======================================================================================================================
    #  Copy the session object to local storage and verify whether it has to be updated with info of a different zone
    #  and/or a different config file. Leave the session object unchanged!
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect = $global:pscsSessionObject.psobject.Copy()
    if ($Zone -eq $defaultZone)             { $Zone = $Connect.Zone }
    if ($ConfigFile -eq $defaultConfigFile) { $ConfigFile = $Connect.ConfigFile }
    $contextSwitch = ($Zone -ne $Connect.Zone) -or ($ConfigFile -ne $Connect.ConfigFile)
    if ($contextSwitch)
    {
        Write-Warning "Tempory context switch to zone $Zone"
        $Connect = Get-CSConfig -ShowKeys -Zone $Zone -ConfigFile $ConfigFile
    }
    # ======================================================================================================================
    #  Use the Invoke-CSApiCall with the listVirtualMachines api function to verify the existance of the specified VM
    # ----------------------------------------------------------------------------------------------------------------------
    try   { $lvmInfo = (Invoke-CSApiCall -Command listVirtualMachines -Parameters "name=$($Server.ToLower())" -Connect $Connect -Verbose:$doVerbose).listvirtualmachinesresponse.virtualmachine } 
    catch { Write-Warning "Specified VM does not exist"; break }
    if ($lvmInfo -eq $null) { Write-Warning "Specified VM does not exist in zone $($Connect.Zone)"; break }
    # ======================================================================================================================
    #  Update the connect object so when used it will start a console session
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect.Type       = "console"
    $Connect.Command    = "cmd=access"
    $Connect.Parameters = ("vm={0}" -f $lvmInfo.Id)
    $Connect.Format     = "XML"
    # ======================================================================================================================
    #  Multiple browser has been depreciated. Only IE is now supported
    #  Build a signed api call (URL Query String) using the details provided. Beware: Base64 does not deliver a string
    #  which complies with the URL encoding standard!
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Connecting to $Server in zone $Connect.Zone"
    $csUrl = Get-APIWebRequest -InputObject $Connect -Verbose:$doVerbose -Debug:$doDebug
    if ($doVerbose) { Write-Verbose "POST $csUrl" }
    # Start the browser window
    $ie = New-Object -ComObject "InternetExplorer.Application"
    $ie.AddressBar = $false
    $ie.MenuBar    = $false
    $ie.ToolBar    = 0
    $ie.Width      = 1060
    $ie.Height     = 850
    $ie.Navigate($csUrl)
    # Cleanup when ready......
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ie) | out-null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Remove-Variable ie
    # Restore original context (if needed)
    if ($contextSwitch) { Write-Verbose "Context switch back to zone $($global:pscsSessionObject.Zone)" }
    # ======================================================================================================================
    #  Console has been started (or not). Exit
    # ----------------------------------------------------------------------------------------------------------------------
}
New-Alias -Name scs -value Start-CSConsoleSession -Description "Start a Cloudstack console session" -Option ReadOnly -Scope Global -Force

############################################################################################################################
#  Connect-CSManager
#    This function will connect to the active/selected CS Manager server. It will obtain a list of available api's
#    and it will convert them into 'regular' Powershell functions. These functions will be propagated via the main
#    psCloudstack module.
############################################################################################################################
function Connect-CSManager
{
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
  
 .Parameter Zone
    Use the named zone connetion data from the configuration file. If no name is specified, the dataset marked
    "Default" will be used. If that does not exist the 1st dataset in the file will be used.
  
 .Parameter ConfigFile
    The path and name of a config file from which the session details will be read.
    By default $Env:LocalAppData\psCloudstack.config will be used, but a different file can be specified.

 .Parameter Silent
    Suppress the welcome message

 .Outputs
    All available Cloudstack api calls as PowerShell functions

 .Example
    # Connect and create the api functions
    C:\PS> Connect-CSManager
    Welcome to psCloudstack V3.4.1 - Generating 458 api functions for you
    
    C:\PS> listUsers -listall

    account             : admin
    accountid           : f20c65de-74b8-11e3-a3ac-0800273826cf
    accounttype         : ..........................
    
  .Notes
    psCloudstack   : V3.4.1
    Function Name  : Connect-CSManager
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([Parameter(Mandatory = $false)][string]$Zone = $defaultZone,
      [Parameter(Mandatory = $false)][string]$ConfigFile = $defaultConfigFile,
      [Parameter(Mandatory = $false)][switch]$Silent)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #   The api parameter types differ in name from the Powershell types. Create a translation table to deal with this.
    #   Beware: The unix date format yyyy-MM-dd has no counterpart in Powershell, therefore its replaced by type string
    # ----------------------------------------------------------------------------------------------------------------------
    $trnTable  = @{ "boolean" = "switch"; "date" = "string"; "integer" = "int32"; "list" = "string[]"; "long" = "int64";
                    "map" = "string[]"; "short" = "int16"; "string" = "string"; "uuid" = "string"; "tzdate" = "string" }
    $csRole    = @("User","Admin","Domain Admin")
    # ======================================================================================================================
    #  New connection request so create a new session object and load the config file details into it.
    # ----------------------------------------------------------------------------------------------------------------------
    New-pscsSessionObject
    Set-pscsSessionObject -csObject (Get-CSConfig -ShowKeys -Zone $Zone -ConfigFile $ConfigFile)
    Set-pscsSessionObject -ConfigFile $ConfigFile
    # ======================================================================================================================
    #  Copy the session object to local storage and verify whether it has to be updated with info of a different zone
    #  and/or a different config file. Also update the session object!
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect = $global:pscsSessionObject.psobject.Copy()
    if ($Zone -eq $defaultZone)             { $Zone = $Connect.Zone }
    if ($ConfigFile -eq $defaultConfigFile) { $ConfigFile = $Connect.ConfigFile }
    if (($Zone -ne $Connect.Zone) -or ($ConfigFile -ne $Connect.ConfigFile))
    {
        $Connect = Get-CSConfig -ShowKeys -Zone $Zone -ConfigFile $ConfigFile
        Set-pscsSessionObject -csObject $Connect
        Set-pscsSessionObject -ConfigFile $ConfigFile
    }
    # ======================================================================================================================
    #   Write the welcome message (can only be done when the session object is present)
    # ----------------------------------------------------------------------------------------------------------------------
    if (!$Silent) { Write-Host -f yellow ("Welcome to psCloudstack V{0}, ..." -f $pscsVersion) }
    # ======================================================================================================================
    #   Get a list of all available api's and convert them into regular Powershell functions. Including embedded help!
    # ----------------------------------------------------------------------------------------------------------------------
    $laRSP = (Invoke-CSApiCall listApis -Format XML -Verbose:$false).listapisresponse
    if ($laRSP.success -eq "false") { return $laRSP }
    $csUser = (Invoke-CSApiCall listUsers -Format xml).listusersresponse.user|? apikey -eq $Connect.Api
    $csParent = (Invoke-CSApiCall -Command listDomains -Parameters id=$($csUser.domainid) -Format XML).listdomainsresponse.domain.parentdomainname
    if (!$Silent) { Write-Host -f yellow "You are connected as $($csRole[$csUser.AccountType]) $($csUser.Username) to domain $csParent/$($csUser.domain)" }
    Write-Verbose "Collecting api function details for $($Connect.Zone)"
    $apiCnt = 0
    foreach ($api in $laRSP.api)
    {
        # -------------------------------------------------------------------------------
        #  Get all possible api parameters and create a sorted list of unique names.
        #  Also turn this list into a spaced string which can be used for skipping
        #  non-cloudstack parameters when building the API call
        # -------------------------------------------------------------------------------
        $apiName = $api.name; $prmList = ""; $apiCnt += 1
        [string[]]$prmNames = $api.params.name|sort-object -unique
        $prmCount = $prmNames.Count; $prmCheck = ""
        if ($prmCount -gt 0) { $prmCheck = $prmNames.ToLower() -join " " }
        # -------------------------------------------------------------------------------
        #  Get all possible api responses and create a sorted list. With only 2 response
        #  values (displaytext & success) the api call result will be a boolean
        # -------------------------------------------------------------------------------
        [string[]]$rspNames = $api.response.name|sort-object -unique
        $rspCount = $rspNames.Count
        # -------------------------------------------------------------------------------
        #  Is it an asynchronous api?
        # -------------------------------------------------------------------------------
        $asyncApi = $($api.isasync) -eq "true"
        # -------------------------------------------------------------------------------
        #  Build a sorted (and pretty formatted) list of related api's 
        # -------------------------------------------------------------------------------
        $linkApi = "None"
        if ($api.related.length -gt 0) { $linkApi  = ($api.related.Split(",")|sort-object -unique) -join "`r`n- " }
        $asyncMark = ""; if ($asyncApi) { $asyncMark = "(A)" }
        Write-Verbose (" {0:0##} - $apiName {1}" -f $apiCnt,$asyncMark)
        # ------------------------------------------------------------------------------------------------------------------
        #  Start the build of the api function code. Define the function as global so it will 'survive' the script ending
        #  The function code is build as a Here-String for which some parts will be generated dynamically
        # ------------------------------------------------------------------------------------------------------------------
        $apiFunction =
@"
function global:$apiName
{
<# 
 .Synopsis
  $($api.description)

 .Description
  $($api.description)
    Asynch: $($api.isasync)


"@
        # ------------------------------------------------------------------------------------------------------------------
        #  Build a neatly formatted list of parameters, make sure mandatory and type settings are correct
        # ------------------------------------------------------------------------------------------------------------------
        foreach ($prm in ($api.params|sort name -unique))
        {
            $apiFunction += " .Parameter {0}`r`n     {1}`r`n" -f $prm.name,$prm.description
            $prmRequired = ($prm.required -eq "true"); $prmType = $trnTable["$($prm.type)"]
            $prmList += ("[Parameter(Mandatory=`${0})][{1}]`${2},`r`n      " -f $prmRequired,$prmType,$prm.name)
        }
        if ($asyncApi)
        {
            $apiFunction += " .Parameter NoWait`r`n     Do not wait for the job to complete. Return the result(s) immediate after starting the job`r`n"
            $prmList     += "[Parameter(Mandatory=`$false,ParameterSetName='NoWait')][switch]`$NoWait,`r`n      "
            $apiFunction += " .Parameter Wait`r`n     Wait xxx seconds for the job to complete before returning results. (Default: Wait for ever)`r`n"
            $prmList     += "[Parameter(Mandatory=`$false,ParameterSetName='Wait')][int32]`$Wait=-1,`r`n      "
        }
        if ($prmList -ne "") { $prmList = $prmList.TrimEnd(",`r`n      ") }
        $apiFunction += "`r`n .Outputs`r`n  System.Object`r`n"
        foreach ($rsp in $api.response|sort-object name) { if ($rsp) { $apiFunction += "`r`n  - {0,-25}{1}" -f $rsp.name,$rsp.description } }
        $apiFunction +=
@"


 .Notes
    psCloudstack   : $pscsVersion
    Function Name  : $apiName
    Author         : Hans van Veen
    Requires       : PowerShell V3
 
 .Link
    Related functions (aka API calls) are:
    - $linkApi

#>
[CmdletBinding(PositionalBinding=`$false, DefaultParameterSetName="$apiName")] 
param($prmList)
    # ======================================================================================================================
    #  Procees common parameters
    `$boundParameters = `$PSBoundParameters
    `$doDebug   = (`$DebugPreference   -eq "Continue")
    `$doVerbose = (`$VerbosePreference -eq "Continue")
    if (`$boundParameters.ErrorAction -ne `$null)   { `$ErrorActionPreference = `$boundParameters.ErrorAction }
    if (`$boundParameters.WarningAction -ne `$null) { `$WarningPreference     = `$boundParameters.WarningAction }
    # ======================================================================================================================
    #  Local & Global variables
    # ----------------------------------------------------------------------------------------------------------------------
    [string[]]`$Parameters = `$null
    `$asyncApi = "$asyncApi" -eq "True"
    # ======================================================================================================================
    #  Verify the active session object. Reload psCloudstack if it has been tampered with
    # ----------------------------------------------------------------------------------------------------------------------
    if (`$pscsSessionObject.Secret -ne (Get-pscsSessionObjectHash))
    {
        Write-Warning "Invalid session object detected, reloading psCloudstack...."
        Import-Module -Name  psCloudstack -Force -ea SilentlyContinue
        rv -Name pscsSessionObject -Scope Global
        Connect-CSManager
        Return
    }
    # ======================================================================================================================
    #  Build the api call and issue it. Non-cloudstack parameters are skipped and list parameter values are joined
    # ----------------------------------------------------------------------------------------------------------------------
    foreach (`$prmName in `$boundParameters.Keys)
    {
        if ("$prmCheck".Contains(`$prmName.ToLower()))
        {
            `$prmValue = `$boundParameters["`$prmName"]
            [string[]]`$Parameters += "`$prmName=`$(`$prmValue -join ",")"
        }
    }
    `$apiResponse = Invoke-CSApiCAll $apiName `$Parameters -Verbose:`$doVerbose -Debug:`$doDebug

"@
        # ------------------------------------------------------------------------------------------------------------------
        #  Code section for asynchronous jobs
        # ------------------------------------------------------------------------------------------------------------------
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
    return
}

"@
        # ------------------------------------------------------------------------------------------------------------------
        #  Code section for synchronous jobs.
        # ------------------------------------------------------------------------------------------------------------------
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
#  Invoke-CSApiCall
#    This function will use the stored connection info to build and issue a valid Cloudstack api call
#    This call can either be directed to the secure or unsecure port
############################################################################################################################
function Invoke-CSApiCall
{
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
    When this switch is specified the api call will be directed to the unsecure port


 .Outputs
    An XML or JSON formatted object which contains all content output returned by the api call
    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Invoke-CSApiCall
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([parameter(Mandatory = $true,ValueFromPipeline=$true)][string]$Command,
      [Parameter(Mandatory = $false)][string[]]$Parameters=$null,
      [Parameter(Mandatory = $false)][ValidateSet("XML","JSON")] [string]$Format="XML",
      [Parameter(Mandatory = $false)][string]$Server,
      [Parameter(Mandatory = $false)][int]$SecurePort,
      [Parameter(Mandatory = $false)][int]$UnsecurePort,
      [Parameter(Mandatory = $false)][string]$Apikey,
      [Parameter(Mandatory = $false)][string]$Secret,
      [Parameter(Mandatory = $false)][switch]$UseSSL,
      [Parameter(Mandatory = $false)][psobject]$Connect)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Trap all errors and return them in a fashionable way...
    # ----------------------------------------------------------------------------------------------------------------------
    trap
    {
        Write-Verbose "Error found: $_"
        $errCode = "1"; $errMsg = $iwr.Message; $cmdIdent = "{0}response" -f $Command.ToLower()
        if ($errMsg -match "^\d+") { $errCode = $matches[0]; $errMsg = $errMsg.SubString($errCode.Length) }
        Write-Host "API Call Error: $errMsg" -f DarkBlue -b Yellow
        [xml]$response = "<?xml version=`"1.0`" encoding=`"UTF-8`"?>
                          <$cmdIdent psCloudstack-version=`"$pscsVersion`">
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
    # ======================================================================================================================
    #  Clone the connection details from the session objec.
    # ----------------------------------------------------------------------------------------------------------------------
    if (!$Connect) { $Connect = $global:pscsSessionObject.psobject.Copy() }
    # ======================================================================================================================
    #  Use the config details to see whether there are overrides....
    # ----------------------------------------------------------------------------------------------------------------------
    if ($Server -ne "")      { $Connect.Server = $Server }
    if ($SecurePort -ne 0)   { $Connect.SecurePort = $SecurePort }
    if ($UnsecurePort -ne 0) { $Connect.UnsecurePort = $UnsecurePort }
    if ($Apikey -ne "")      { $Connect.api = $Apikey }
    if ($Secret -ne "")      { $Connect.key = $Secret }
    if ($UseSSL)             { $Connect.UseSSL = $true }
    # ======================================================================================================================
    #  Add extra items to the Connect object
    # ----------------------------------------------------------------------------------------------------------------------
    $Connect|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Type       -Value "api"
    $Connect|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Command    -Value "command=$Command"
    $Connect|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Parameters -Value $Parameters
    $Connect|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Format     -Value $Format
    # ======================================================================================================================
    #  Build a signed api call (URL Query String) using the details provided. Beware: Base64 does not deliver a string
    #  which complies with the URL encoding standard!
    # ----------------------------------------------------------------------------------------------------------------------
    $csUrl = Get-APIWebRequest -InputObject $Connect -Verbose:$doVerbose -Debug:$doDebug
    $prefProgress = $progressPreference; $progressPreference = 'silentlyContinue'
    $Response = Invoke-WebRequest "$csUrl" -UseBasicParsing -ErrorVariable iwr -Verbose:$doVerbose -Debug:$doDebug
    $progressPreference = $prefProgress
    # ======================================================================================================================
    #  Now return the content in the requested format
    # ----------------------------------------------------------------------------------------------------------------------
    $Content = $Response.Content
    if ($Format -eq "XML") { [xml]$Content = $Response.Content }
    Write-Output $Content
}

############################################################################################################################
####                                      Internal-Only (Non-Exported) Functions                                        ####
############################################################################################################################
#  New-pscsSessionObject
#   Creates an (empty) pscsSessionObject for psCloudstack This object is essential to all psCloudstack functions!
# --------------------------------------------------------------------------------------------------------------------------
function New-pscsSessionObject
{
    if ($global:pscsSessionObject -ne $null) { rv -Name pscsSessionObject -Scope Global -Force}
    $global:pscsSessionObject = New-Object -TypeName PSObject
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Created      -Value (Get-Date)
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Version      -Value $pscsVersion
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Secret       -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Zone         -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Server       -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name SecurePort   -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name UnsecurePort -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Api          -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name Key          -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name UseSSL       -Value $Null
    $global:pscsSessionObject|Add-Member NoteProperty -TypeName psCloudstack.Config -Name ConfigFile   -Value $Null
}

############################################################################################################################
#  Set-pscsSessionObject
#   Fill the session object with active session information. The session info can be passed per item or as an object
# --------------------------------------------------------------------------------------------------------------------------
function Set-pscsSessionObject
{
[CmdletBinding()]
param([parameter(Mandatory = $false)][string]$Zone = $Null,
      [parameter(Mandatory = $false)][string]$NewName = $Null,
      [parameter(Mandatory = $false)][string]$Server = $Null,
      [Parameter(Mandatory = $false)][int]$SecurePort = $Null,
      [Parameter(Mandatory = $false)][int]$UnsecurePort = $Null,
      [Parameter(Mandatory = $false)][string]$ApiKey = $Null,
      [Parameter(Mandatory = $false)][string]$Secret = $Null,
      [Parameter(Mandatory = $false)][switch]$UseSSL = $Null,
      [Parameter(Mandatory = $false)][string]$ConfigFile = $Null,
      [Parameter(Mandatory = $false)][psobject]$csObject = $Null)
    $bndPrm = $PSBoundParameters
    # ======================================================================================================================
    #  No current session object yet, than create an empty one
    # ----------------------------------------------------------------------------------------------------------------------
    if ($global:pscsSessionObject -eq $null) { New-pscsSessionObject }
    # ======================================================================================================================
    #  Update the session object with the commandline/parameter content
    # ----------------------------------------------------------------------------------------------------------------------
    if (!$csObject) { $csObject = $bndPrm }
    if ($csObject.Zone)         { $global:pscsSessionObject.Zone         = $csObject.Zone }
    if ($csObject.Server)       { $global:pscsSessionObject.Server       = $csObject.Server }
    if ($csObject.SecurePort)   { $global:pscsSessionObject.SecurePort   = $csObject.SecurePort }
    if ($csObject.UnsecurePort) { $global:pscsSessionObject.UnsecurePort = $csObject.UnsecurePort }
    if ($csObject.Api)          { $global:pscsSessionObject.Api          = $csObject.Api }
    if ($csObject.Key)          { $global:pscsSessionObject.Key          = $csObject.Key }
    if ($csObject.UseSSL)       { $global:pscsSessionObject.UseSSL       = $csObject.UseSSL }
    if ($csObject.ConfigFile)   { $global:pscsSessionObject.ConfigFile   = $csObject.ConfigFile }
    # ======================================================================================================================
    #  Finally add a hash value to the object which can be used to secure/verify the object content
    # ----------------------------------------------------------------------------------------------------------------------
    $global:pscsSessionObject.Secret = Get-pscsSessionObjectHash
    return
}

############################################################################################################################
#  Get-pscsSessionObjectHash
#   Creates a hash using the active pscsSessionObject
# --------------------------------------------------------------------------------------------------------------------------
function Get-pscsSessionObjectHash
{
    # ======================================================================================================================
    #  No current session object yet, than create an empty one
    # ----------------------------------------------------------------------------------------------------------------------
    if ($global:pscsSessionObject -eq $null) { New-pscsSessionObject }
    $resultingHash = ""; $Result = ""
    # ======================================================================================================================
    #  Create 1 long string of items in the object
    # ----------------------------------------------------------------------------------------------------------------------
    $hashFeed = "{0}{7}{1}{5}{9}{3}{6}{2}{4}{8}" -f $global:pscsSessionObject.Zone, $global:pscsSessionObject.Server, $global:pscsSessionObject.Api, `
                                                    $global:pscsSessionObject.Key, $global:pscsSessionObject.SecurePort, $global:pscsSessionObject.UnsecurePort, `
                                                    $global:pscsSessionObject.UseSSL, $global:pscsSessionObject.ConfigFile, $global:pscsSessionObject.Version, `
                                                    (Get-date ($global:pscsSessionObject.Created) -f yyyyMMddHHmmss)
    $sha256Hasher = New-Object System.Security.Cryptography.SHA256Managed
    $ObjecttoHash = [System.Text.Encoding]::UTF8.GetBytes($hashFeed)
    $hashByteArray = $sha256Hasher.ComputeHash($ObjecttoHash)
    foreach($byte in $hashByteArray) { $resultingHash += $byte.ToString() }
    return $resultingHash
}

############################################################################################################################
#  New-CSConfig
#   Returns an (empty) base xml configuration for psCloudstack
# --------------------------------------------------------------------------------------------------------------------------
function New-CSConfig
{
    [xml]$newCfg = "<?xml version=`"1.0`" encoding=`"utf-8`"?>
                    <configuration version=`"3.0`">
                    </configuration>"
    return $newCfg
}

############################################################################################################################
#  Get-APIWebRequest
#   Build the api call signature based upon the command & secret key
# --------------------------------------------------------------------------------------------------------------------------
function Get-APIWebRequest
{
<# 
 .Synopsis
    Create the API web request url

 .Description
    Build the API web request url using the provided command and parameters

 .Parameter InputObject
    Object which contains the request connection details

 .Outputs
    The API web request url

    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Get-APIWebRequest
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([parameter(Mandatory = $true)][psobject]$InputObject)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    $qvReplacement = [ordered]@{ "%"="%25"; " "="%20"; "!"="%21"; "*"="%2A"; "'"="%27"; "("="%28"; ")"="%29"; ";"="%3B"; ":"="%3A"; "@"="%40"; `
                                 "&"="%26"; "="="%3D"; "+"="%2B"; "$"="%24"; ","="%2C"; "/"="%2F"; "?"="%3F"; "#"="%23"; "["="%5B"; "]"="%5D" }
    # ======================================================================================================================
    #  Build the base URL - part 1
    # ----------------------------------------------------------------------------------------------------------------------
    if ($InputObject.UseSSL) {
        Write-Verbose "Secured web request for api call: $($InputObject.Command)"
        $Protocol = "https"
        $Port     = $InputObject.SecurePort
    }
    else {
        Write-Verbose "Unsecured web request for api call: $($InputObject.Command)"
        $Protocol = "http"
        $Port     = $InputObject.UnsecurePort
    }
    $baseUrl = "{0}://{1}:{2}/client/{3}?{4}" -f $Protocol, $InputObject.Server, $Port, $InputObject.Type, $InputObject.Command
    # ----------------------------------------------------------------------------------------------------------------------
    #  Add the quey arguments - create a separate string for this as it needs to be signed
    # ----------------------------------------------------------------------------------------------------------------------
    $queryString = "response={0}" -f $InputObject.Format.ToLower()
    $InputObject.Parameters|%{
        if ($_.Length -gt 0)
        {
            $prmName,$prmVal = $_ -Split "=",2
            if ($prmName -ne 'tags')
            {
                foreach ($qvk in $qvReplacement.keys) { $prmVal = $prmVal.Replace($qvk,$qvReplacement[$qvk]) }
                $queryString += ("&{0}={1}" -f $prmName, $prmVal)
            }
            else
            {
                $tagString = ""; $tagCnt = 0
                foreach ($kvpair in $prmVal.Split(','))
                {
                    $tagKey, $tagValue = $kvpair.Split('=')
                    $tagString += "&tags[$tagCnt].key=$tagKey"
                    if ($tagValue)
                    {
                        foreach ($qvk in $qvReplacement.keys) { $tagValue = $tagValue.Replace($qvk,$qvReplacement[$qvk]) }
                        $tagString += "&tags[$tagCnt].value=$tagValue"
                    }
                    $tagCnt += 1
                }
                $queryString += $tagString
            }
        }
    }
    Write-Verbose "Query String: $queryString"
    # ======================================================================================================================
    #  Build the api signature
    # ----------------------------------------------------------------------------------------------------------------------
    $cryptString = (("apikey={0}&{1}&{2}" -f $InputObject.api, $InputObject.Command, $queryString).split("&")|sort) -join "&"
    $apiSignature = Get-ApiSignature -Command $cryptString -Key $InputObject.key -Verbose:$doVerbose -Debug:$doDebug
    # ======================================================================================================================
    #  Build a signed api call (URL Query String) using the details provided. Beware: Base64 does not deliver a string
    #  which complies with the URL encoding standard!
    # ----------------------------------------------------------------------------------------------------------------------
    $csUrl = "{0}&{1}&apikey={2}&signature={3}" -f $baseUrl, $queryString, $InputObject.api, $apiSignature
    return $csUrl
}


############################################################################################################################
#  Get-ApiSignature
#   Build the api call signature based upon the command & secret key
# --------------------------------------------------------------------------------------------------------------------------
function Get-ApiSignature
{
<# 
 .Synopsis
    Create the API call signature

 .Description
    Build the API call signature based upon the command & secret key.

 .Parameter Command
    The command to create the signature for.

 .Outputs
    Signature string

    
 .Notes
    psCloudstack   : V3.4.1
    Function Name  : Get-ApiSignature
    Author         : Hans van Veen
    Requires       : PowerShell V3

#>
[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Command, [Parameter(Mandatory = $true)][string]$Key)
    $bndPrm = $PSBoundParameters
    if ($bndPrm.Verbose) { $VerbosePreference = "Continue"; $doVerbose = $true } else { $VerbosePreference = "SilentlyContinue"; $doVerbose = $false }
    if ($bndPrm.Debug)   { $DebugPreference   = "Continue"; $doDebug   = $true } else { $DebugPreference   = "SilentlyContinue"; $doDebug   = $false }
    if ($bndPrm.ErrorAction -ne $null)   { $ErrorActionPreference = $bndPrm.ErrorAction }
    if ($bndPrm.WarningAction -ne $null) { $WarningPreference     = $bndPrm.WarningAction }
    # ======================================================================================================================
    #  Load the System.Security object
    # ----------------------------------------------------------------------------------------------------------------------
    $crypt = New-Object System.Security.Cryptography.HMACSHA1
    # ======================================================================================================================
    #  Build the api signature
    # ----------------------------------------------------------------------------------------------------------------------
    Write-Verbose "Crypt Cmd: $Command"
    $crypt.key = [Text.Encoding]::ASCII.GetBytes($Key)
    $cryptBytes = $crypt.ComputeHash([Text.Encoding]::ASCII.GetBytes($Command.ToLower()))
    $apiSignature = [System.Web.HttpUtility]::UrlEncode([System.Convert]::ToBase64String($cryptBytes))
    Write-Verbose "Signature: $apiSignature"
    return $apiSignature
}

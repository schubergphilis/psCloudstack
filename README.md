#psCloudstack#
A PowerShell module which dynamically creates PowerShell functions from all available Cloudstack api's      
Copy **all** files to one of the folders listed in the PSModulePath environment variable.

####To activate:####
Beginning in Windows PowerShell 3.0, installed modules are automatically imported to the session when you use any commands or
providers in the module. However, you can still use the Import-Module command to import the psCloudstack module

####Description:####
Coding PowerShell functions for all available Cloudstack api's.... there are more than 450 of them now!        
You probably think the guy is insane or has to much spare time. I am addicted, but it's neither of that.      
I do agree: coding 450+ functions manually is insane and that's why I came up with psCloudstack.

###The Base Functions###
The psCloudstack module consists of 5 functions which form the base of psCloudstack, and to get things
working you can use the following scenario:
  - Initialize-CSConfig  ---    Create/Update a psCloudstack configuration file and make it active
  - Get-CSConfig         ---    Evaluate the active psCloudstack configuration file
  - Connect-CSManager    ---    Build all entitled api functions  
From this moment on you can use the api functions. See the remainder of this file and CHANGES and EXAMPLES for additional information.


#####1. Initialize-CSConfig#####
This function creates or updates the psCloudstack connection config file. This file (default: %LOCALAPPDATA%\psCloudstack.config)
contains the required connection info for communicating with the Cloudstack Management server, either via the authenticated or
unauthenticated port. It also contains some information about the Cloudstack like the version and number of available api's.

Only api's the user is entitled to are collected and counted!

Required: the name of the Cloudstack management server, the port numbers for the secure and unsecured port (defaults are 808 & 8096),
and your API and secret key.

Use the following command to create the default psCloudstack config file:
```
Initialize-CSConfig -Server <String> [-SecurePort <Int32>] [-UnsecurePort <Int32>] -Apikey <String> -Secret <String>
```
You can also add -UseSSL to the command if you want to use https for calls via the secured port (unsecured is always http)      
Furthermore you can use -Config to specify a file of your own.


#####2. Get-CSConfig#####
This function is used by the *Invoke-CSApiCall* and *Connect-CSManager* functions to retrieve the content from the active       
configuration file. When used interactively, all info will be displayed with exception of the api and secret key.       
If this information is required, use -ShowKeys on the command line.
```
Get-CSConfig [-ConfigFile <String>] [-ShowKeys]
```
By using -ConfigFile the content of another psCloudstack config file can be displayed.


#####3. Set-CSConfig#####
Set the CSCONFIGFILE environment variable to the specified or default value (Default: %LOCALAPPDATA%\psCloudstack.config)       
This environment variable then specifies the active configuration and is used as such by the other psCloudstack functions.      
```
Set-CSConfig [-ConfigFile <String>]
```


#####4. Connect-CSManager#####
This function (and the next) are the core of psCloudstack. As mentioned before, it is impossible to code 450+ functions manually without getting RSI (or worse).

Connect-CSManager uses the Cloudstack listApis api call to collect the details of *all entitled api's* and it will turn them automatically into PowerShell functions.
The api name becomes the function name, the api request parameters become the function parameters and the api response tags become the output fields of the function.
All this information is pasted into a (Here-String based) **global** function template and than executed via the Invoke-Expression command.

```
Connect-CSManager -Verbose
VERBOSE: Generating api functions......
VERBOSE:  001 - listNetworkACLs
VERBOSE:  002 - reconnectHost (A)
          ...
          ...
          ...
VERBOSE:  454 - updateNetworkServiceProvider (A)
VERBOSE:  455 - listUsers
VERBOSE:  456 - findStoragePoolsForMigration
VERBOSE:  457 - listSupportedNetworkServices
VERBOSE:  458 - listIsos
```   
Functions marked with an (A) use async api calls which only return a job id. This job id can be used as input to     
*queryAsyncJobResult* and *listAsyncJobs*

######Work in Progress######
Two extra (but yet inactive) parameters have been added to functions based upon async api calls: *-Wait [sss]* and *-NoWait*     
By default, when a async api call is made, the function will wait infinitely for the api call to complete      
responses.
*-NoWait*     This will cause the function to return the job id as soon as it becomes available.  
*-Wait [sss]* The function will wait for max. sss seconds before the result. If the job has not finished yet, the       
              function will still return the job id. If it has completed the actual api results will be returned.
By default the function will wait forever for the job to complete


#####5. Invoke-CSApiCall#####
This function contains the actual api call logic. An Cloudstack api call has to be formatted in a specific way and      
signed using the users api & secret key. This process is described in detail in the "Cloudstack API Developer's Guide"      
chapter "Calling the Cloudstack API".

Invoke-CSApiCall is used by every api function created via Connect-CSManager (which uses it to get all the available api's),
but it can also be used interactively.

```
Invoke-CSApiCall [-Command] <String> [-Parameters <String[]>] [-Format <String>] [-Server <String>] [-SecurePort <Int32>]
                 [-UnsecurePort <Int32>] [-Apikey <String>] [-Secret <String>] [-UseSSL] [-UseUnsecure]
```

At least the command must be specified and optional some parameters to the command. The other parameters can be used to override 
the settings from the active configuration file.        
By default Invoke-CSApiCAll will return XML formatted output, but JSON is also possible using *-Format JSON*
```
PS> Invoke-CSApiCall -Command listZones name=Bootcamp 

xml                                                               listzonesresponse
---                                                               -----------------
version="1.0" encoding="UTF-8"                                    listzonesresponse


PS> Invoke-CSApiCall -Command listZones name=Bootcamp  -Format JSON
{ "listzonesresponse" : { "count":1 ,"zone" : [  {"id":"755fba3b-a748-4458-a3d2-e149b74da94a","name":"Bootcamp","dns1":"8.8.8.8","dns2":"8.8.4.4","internaldns1":"192.168.56.11","guestcidraddress":"10.1.1.0/24","networktype":"Advanced","securitygroupsenabled":false,"allocationstate":"Enabled","zonetoken":"277b0fae-5b08-3a61-837a-b55475bac83b","dhcpprovider":"VirtualRouter","localstorageenabled":false} ] } }
```

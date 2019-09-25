#Change History#

####V1.1####
April 4, 2014 - psCloudstack V1.1 was presented to a group of enthusiastic colleagues. As a result this version is now published on GitHub.com
There are still a couple of ToDo items and they will be taken care of in good time (or sooner if possible/required)

####V1.2####
April 9, 2014 - Connect-CSManager (the base function which builds all the api functions) had a shortcoming, all api function parameters were handled as strings. 
This is no problem for the actual api call since that's string oriented anyway (web request url). What might be considered a problem is the PowerShell parameter 
handling of the api functions, everything got handled as if it were a string, even integers, booleans, etc.  
Connect-CSManager now creates a better (formatted) list of api function parameters, including mandatory and type settings. The following 'translation' 
table is used to convert the 'Unix types' to 'PowerShell types'

         | --------- | -------- |     | --------- | -------- |
         | Unix type | PS type  |     | Unix type | PS type  |
         | --------- | -------- |     | --------- | -------- |
         | boolean   | switch   |     | map       | string   |
         | date      | string   |     | short     | int16    |
         | integer   | int32    |     | string    | string   |
         | list      | string[] |     | uuid      | string   |
         | long      | int64    |     | tzdate    | string   |
         | --------- | -------- |     | --------- | -------- |

In psCloudstack the Cloudstack api boolean is replaced by a PowerShell switch parameter which takes no value at all.
This means that; false is not specified and true when specified

A welcome message has been added to Connect-CSManager, if you find it annoying use -Silent to suppress it.

####V2.0####
April 14, 2014 - A rather intense update. Removed a lot of ugly code and improved sync/async code streams.
Most important change: asynch functions now support -Wait/-NoWait
- In V1.2 the Cloudstack api boolean was replaced by a PowerShell switch parameter. Some thought this to be a setback.  
  Created the possibility of using Unix style booleans again by introducing -CommandStyle [Unix|Windows] for Connect-CSManager  
  This option can also be set via the config file, in the <connect> section the line <command style="xxxxxx" /> has been added  
- Asynchronous functions now support -Wait xxx and -NoWait (mutually exclusive!) By default when a asynchronous function is called  
  the function will wait until the action is completed, and when completed it will show job details.  
  -Wait xxx the number of seconds to wait can specified, a warning will be issued when the job has not completed within this time.  
  -NoWait will return the job details immediately.
- The embedded help details have been improved. Mixed usage of Input and parameter specifications were disturbing
- Function code for synchronous and asynchronous functions have been separated. The function now only contains the code stream  
  it requires.
- Removed some old 'debug-like' lines of code.

####V2.0.1####
Some small bugfixes;
- Initialize-CSConfig now works like documented
- Get-CSConfig does not do a implied Set-CSConfig anymore
- Hide Invoke-WebRequest progressbar
- Removed version warning, update config instead using internal Update-ApiInfo function

####V2.1.0####
Asynchronous jobs now return the job status and if possible the resulting job details
If output is assigned to a variable, index 0 will show the job result and index 1 the job details.

####V2.1.1####
Improved: Now returning all api responses including empty ones
Fixed: api response processing. listRegions (and others) sometimes produced an extra empty object

####V2.1.2####
Improved: Creation of output objects. GetType now returns some useful info of the object (mostly of cosmetic nature)
Improved: Error handling of the Invoke-CSApiCall, now returning more error details
Improved: Error handling of the asynchronous calls, also returning more error details
Improved: Every api function now returns a completionStatus field specifying the overall end result.

####V2.2.0####
Raised Powershell version dependency to V3 (dependency already existed but was never documented)
Changed parameter check. Now comparing against dynamic include list (provided by listApis) in stead of static (hardcoded) exclude list
Added ErrorAction and WarningAction handling to all functions (static & dynamic)

####V3.0.0####
Got rid of one configuration file per Cloudstack server/environment. psCloudstack now uses one configutration file to manage multiple
(named) Cloudstack server connections. The Initialize-CSConfig function has been replaces with the Add-CSConfig and Remove-CSConfig
functions, and the Connect-CSManager, Set-CSConfig and Get-CSConfig functions have been changed to accomodate this.
Connect-CSManager now uses a 'name' parameter to select the required connection configuration form the configuration file.
If the parameter is not used, the configuration named 'Default' will be used, and if that one does not exists, the 1st configuration
in the configuration file will be used.
Last but not least. Displaying final status results of an asynchroneous jobs was unreliable, not every asynchroneous job has a clear
recognizable list function available in the Related Functions part. Connect-CSManager now builds a list of asynchroneous functions
with their matching list function, and this list is now used to find the match.

####V3.0.1####
Removed the automatic result list for asynchroneous api's. The 'standard' job status object has a jobstatus item which contains almost everything one needs.
Besides; you know best (I hope) what to do with the completion status information ;)

####V3.2.1####
A lot of small and bigger things.
- Bug Fix:
  Bug Reported by: James Richards <james.richards@citrix.com>
  The Secure/Unsecure (http/https) selection was not correct. You could choose http but were still directed to https
- New Functionality:
  Start-CSConsoleSession to start a console session with the cloud VM of your choice. No need to use Connect-CSManager first,
  as long as the the VM exists in the specified zone the console will pop up
- Code Changes:
  Simplified/streamlined some code. Both Invoke-CSApiCall and Start-CSConsoleSession use the same logic to build the connection URL.
  This code is now isolated in the form of an internal function.

####V3.3.0####
- Bug Fix:
  Bug Reported by: Maurico Schaepers (https://github.com/mschaepers)
  psCloudstack uses [System.Web.HttpUtility]::UrlEncode for normalizing URL's and this sometimes causes problems for values passed to Cloudstack.
  This method has been replaced with a tailor made method to prevent the erroneous behavior
- Code changes
  Every execution of a psCloudstack function would result in 1 or more reloads of the configuration file. The file is now only read once and its
  content is saved in a (secured) memory object.

####V3.3.1####
- Code Change: Start-CSConsoleSession
  Open the console browser window is a minimal as possible window. This is done for IExplorer, Mozzila/Firefox and Chrome.
  If the default browser is not recognized Start-CSConsoleSession will use IExplorer.

####V3.4.1####
- Code Change: Start-CSConsoleSession
  Drop multi browser support, only IE supported  


Kind Regards,
Hans van Veen

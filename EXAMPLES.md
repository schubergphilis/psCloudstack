# psCloudstack Examples #

This file shows you some of the possibilities of psCloudstack.

#### In the beginning there was.... ####

A bare and empty PowerShell function landscape

```ps1
PS C:\> ls function:

CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        A:
Function        B:
    ........
    ........
    ........
Function        Y:
Function        Z:
```

#### Bringing psCloudstack to the surface.... ####

The sea of functions started to fill............

```ps1
PS C:\> Import-Module psCloudstack
PS C:\> ls function:

CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        A:
Function        Add-CSConfig                                       psCloudstack
    ........
    ........
Function        Connect-CSManager                                  psCloudstack
Function        Convert-CSConfig                                   psCloudstack
    ........
    ........
Function        Get-CSConfig                                       psCloudstack
    ........
    ........
Function        Invoke-CSApiCall                                   psCloudstack
Function        J:
    ........
    ........
Function        R:
Function        Remove-CSConfig                                    psCloudstack
Function        S:
Function        Set-CSConfig                                       psCloudstack
    ........
    ........
Function        Y:
Function        Z:

```

#### Creating the Cloudstack api functions.... ####

And all was #up and running#, all entitled api functions at your feet........

```ps1
PS C:\> Connect-CSManager [-Zone ...]
PS C:\> ls function:

CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        A:
Function        activateProject                                    psCloudstack
Function        addAccountToProject                                psCloudstack
Function        addBaremetalDhcp                                   psCloudstack
Function        addBaremetalHost                                   psCloudstack
Function        addBaremetalPxeKickStartServer                     psCloudstack
Function        addBaremetalPxePingServer                          psCloudstack
    ........
    ........
Function        updateZone                                         psCloudstack
Function        uploadCustomCertificate                            psCloudstack
Function        uploadVolume                                       psCloudstack
Function        V:
Function        W:
Function        X:
Function        Y:
Function        Z:
```

#### You are not alone.... ####

Reach out for help if needed, use *Get-Help 'api-name'* to get help on the function usage, for example;

```ps1

PS> help listZones

PS C:\> help listZones

NAME
    listZones

SYNOPSIS
    Lists zones


SYNTAX
    listZones [-available <Object>] [-domainid <Object>] [-id <Object>] [-keyword <Object>] [-name <Object>] [-networktype
    <Object>] [-page <Object>] [-pagesize <Object>] [-showcapacities <Object>] [<CommonParameters>]


DESCRIPTION
    Lists zones
      Asynch: false


RELATED LINKS
    Related functions (aka API calls) are:

REMARKS
    To see the examples, type: "get-help listZones -examples".
    For more information, type: "get-help listZones -detailed".
    For technical information, type: "get-help listZones -full".
    For online help, type: "get-help listZones -online"
```


### api Function Usage ###

Use the functions like you would use any Powershell function/cmdlet. Start parameters with a "-" sign and keep a space between
the parameter name and parameter value. All the results are returned as a single System.Object, one for each item returned.     
Adding -Verbose to the command will display the details about/from the api call.

```ps1
PS C:\> listZones -Name Bootcamp

allocationstate       : Enabled
dhcpprovider          : VirtualRouter
dns1                  : 8.8.8.8
dns2                  : 8.8.4.4
guestcidraddress      : 10.1.1.0/24
id                    : 755fba3b-a748-4458-a3d2-e149b74da94a
internaldns1          : 192.168.56.11
localstorageenabled   : false
name                  : Bootcamp
networktype           : Advanced
securitygroupsenabled : false
zonetoken             : 277b0fae-5b08-3a61-837a-b55475bac83b

```

The equivalent Invoke-CSApiCall command would be:

```ps1
PS> Invoke-CSApiCall listZones name=Bootcamp

xml                                                               listzonesresponse
---                                                               -----------------
version="1.0" encoding="UTF-8"                                    listzonesresponse
```

### Using output to feed others.... ###

Capture the output from one call and use it to 'feed' another api function call

```ps1
PS C:\> $no = listNetworkOfferings -name DefaultIsolatedNetworkOfferingWithSourceNatService
PS C:\> $di = listDomains -name Wayne
PS C:\> $zi = listZones -name Bootcamp
PS C:\> $nn = createNetwork -account batman -displaytext batman-001 -name batman-001 -domainid $di.id -displaynetwork true -networkofferingid $no.id -zoneid $zi.id
PS C:\> listNetworks -listAll true  # Output should match the 'value' of $nn!

account                     : batman
acltype                     : Account
broadcastdomaintype         : Vlan
canusefordeploy             : true
cidr                        : 10.1.1.0/24
displaynetwork              : true
displaytext                 : batman-001
dns1                        : 8.8.8.8
dns2                        : 8.8.4.4
domain                      : Wayne
domainid                    : 6c649fc2-0a73-4c7d-85a3-1b2d8bca7b4a
gateway                     : 10.1.1.1
id                          : 5b3d5821-2d9a-419d-8556-668f0fc15a4a
ispersistent                : false
issystem                    : false
name                        : batman-001
netmask                     : 255.255.255.0
networkdomain               : wayneindustries.local
networkofferingavailability : Required
networkofferingconservemode : true
networkofferingdisplaytext  : Offering for Isolated networks with Source Nat service enabled
networkofferingid           : e94d7e41-1c33-45a5-bcda-ff429d7e6637
networkofferingname         : DefaultIsolatedNetworkOfferingWithSourceNatService
physicalnetworkid           : 0001a737-6fe0-4822-9cb1-8f9567b6445c
related                     : 5b3d5821-2d9a-419d-8556-668f0fc15a4a
restartrequired             : false
service                     : {Dns, StaticNat, Firewall, Lb...}
specifyipranges             : false
state                       : Allocated
traffictype                 : Guest
type                        : Isolated
zoneid                      : 755fba3b-a748-4458-a3d2-e149b74da94a
zonename                    : Bootcamp
```

### and I leave the rest to your imagination! ###

## Converting existing configuration files ##

For example 3 configuration files;

```ps1
PS> cat C:\Users\'username'\AppData\Local\psCloudstack.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="2.0">
  <connect>
    <server address="test.cloudstack.com" secureport="8080" unsecureport="8096" usessl="true" />
    <authentication api="rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr" key="ssssssssssssssssssssssssssssss" />
  </connect>
  <api version="4.4.4" count="266" />
</configuration>
PS>
```

```ps1
PS> cat C:\Users\'username'\AppData\Local\psCloudstack-Test1.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="2.0">
  <connect>
    <server address="test1.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" key="wwwwwwwwwwwwwwwwwwwwwwwwwwwwww" />
  </connect>
  <api version="4.4.4" count="266" />
</configuration>
PS>
```

```ps1
PS> cat C:\Users\'username'\AppData\Local\psCloudstack-Test2.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="2.0">
  <connect>
    <server address="test2.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" key="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy" />
  </connect>
  <api version="4.4.4" count="266" />
</configuration>
PS>
```

##### Step 1 - No parameters #####

```ps1
PS> Convert-CSConfig -Verbose
VERBOSE: Converting config file "C:\Users\'username'\AppData\Local\psCloudstack.config"
VERBOSE: default psCloudstack config has been updated
PS> cat C:\Users\'username'\AppData\Local\psCloudstack.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="3.0">
  <connect name="Default">
    <server address="test.cloudstack.com" secureport="8080" unsecureport="8096" usessl="true" />
    <authentication api="rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr" key="ssssssssssssssssssssssssssssss" />
  </connect>
</configuration>
PS>
```

##### Step 2 - Specify source file and connection name #####

```ps1
PS> Convert-CSConfig -ConfigFile C:\Users\'username'\AppData\Local\psCloudstack-Test1.config -Name Test1 -Verb
VERBOSE: Converting config file "C:\Users\'username'\AppData\Local\psCloudstack-Test1.config"
VERBOSE: Merging psCloudstack config data
VERBOSE: default psCloudstack config has been updated
PS> cat C:\Users\'username'\AppData\Local\psCloudstack.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="3.0">
  <connect name="Default">
    <server address="test.cloudstack.com" secureport="8080" unsecureport="8096" usessl="true" />
    <authentication api="rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr" key="ssssssssssssssssssssssssssssss" />
  </connect>
  <connect name="Test1">
    <server address="test1.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" key="wwwwwwwwwwwwwwwwwwwwwwwwwwwwww" />
  </connect>
</configuration>
PS>
```

##### Step 3- Specify source file, NO connetion name #####

```ps1
PS> Convert-CSConfig -ConfigFile C:\Users\'username'\AppData\Local\psCloudstack-Test2.config -Verb
VERBOSE: Converting config file "C:\Users\'username'\AppData\Local\psCloudstack-Test2.config"
VERBOSE: Merging psCloudstack config data
WARNING: Duplicate name found, using "Default+"
VERBOSE: default psCloudstack config has been updated
PS> cat C:\Users\'username'\AppData\Local\psCloudstack.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="3.0">
  <connect name="Default">
    <server address="test.cloudstack.com" secureport="8080" unsecureport="8096" usessl="true" />
    <authentication api="rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr" key="ssssssssssssssssssssssssssssss" />
  </connect>
  <connect name="Test1">
    <server address="test1.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" key="wwwwwwwwwwwwwwwwwwwwwwwwwwwwww" />
  </connect>
  <connect name="Default+">
    <server address="test2.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" key="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy" />
  </connect>
</configuration>
PS>
```

##### Step 4 - Rename the Default+ connection #####

```ps1
PS> Set-CSConfig -Name "Default+" -NewName "Test2" -Verbose
VERBOSE: Reading psCloudstack config file
VERBOSE: psCloudstack config has been updated
PS> cat C:\Users\'username'\AppData\Local\psCloudstack.config
<?xml version="1.0" encoding="utf-8"?>
<configuration version="3.0">
  <connect name="Default">
    <server address="test.cloudstack.com" secureport="8080" unsecureport="8096" usessl="true" />
    <authentication api="rrrrrrrrrrrrrrrrrrrrrrrrrrrrrr" key="ssssssssssssssssssssssssssssss" />
  </connect>
  <connect name="Test1">
    <server address="test1.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="vvvvvvvvvvvvvvvvvvvvvvvvvvvvvv" key="wwwwwwwwwwwwwwwwwwwwwwwwwwwwww" />
  </connect>
  <connect name="Test2">
    <server address="test2.cloudstack.com" secureport="443" unsecureport="80" usessl="true" />
    <authentication api="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" key="yyyyyyyyyyyyyyyyyyyyyyyyyyyyyy" />
  </connect>
</configuration>
PS>
```
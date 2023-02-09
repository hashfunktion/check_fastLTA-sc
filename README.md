# Check FastLTA Silent Cube
### Icinga check-plugin for FastLTA Silent Cube
This is a basic check-plugin for icinga based on SNMP to check Silent Cubes from FastLTA.

[TOC]


##Usage

	.\check_fastLTA-sc.pl -H <HOSTNAME> -C <SNMP-Community> -o <check option> -w <warning threshold> -c <critical threshold> [ -h <for help/usage> ]


[-H]	Host to check

[-o]	Define the part of the system you want to check

>Existing check options `$fastLTA_variable$`:

	headunit-status    ->   Working state from the Headunit  
	replica-status     ->   Checks if the replication works  
	sc-status          ->   Checks the Silent Cube status  
	sc-capusage        ->   Check the percentage usage of the silentcube
	sc-disks           ->   Check the disks of the silentcube
	sc-fans            ->   Check the fans of the silentcube
	sc-psus            ->   Check the psus of the silentcube

[-w]  Warning threshold

[-c]  	Critical threshold

[-h]	Show this page

## Examples / Templates

### commands.conf
	object CheckCommand "fastLTA-sc" {
	import "plugin-check-command"

	  command = [ PluginDir + "/check_fastLTA-sc" ]

	   arguments = {
        "-H" = "$fastLTA_address$"
        "-o" = "$fastLTA_variable$"
        "-w" = "$fastLTA_warn$"
        "-c" = "$fastLTA_crit$"
		}

    vars.fastLTA_address = "$address$"
	}

### Arguments

| CheckCommand Variable | Plugin Argument                        | Description         |
 ---------------------- | ---------------------------- | ------------------
| `$fastLTA_address$`|`-H`|Address of the server|
| `$fastLTA_variable$`|`-o`|Variable that that will be checked|
| `$fastLTA_warn$`| `-w` | Warning threshold|
| `$fastLTA_crit$`| `-c` |Critical threshold|

### Using Icinga Director
#### Datalist
List name: fastLTA_variable-list
| Key                     | Lable                        	|
|-------------------	|------------------------------	|
| headunit-status | Headunit status              	|
| replica-status    | Replication status           	|
| sc-status            | Operation status Silent Cube 	|
| sc-capusage      | Percentage usage Silent Cube 	|

#### Datafield
Field name: fastLTA_variable
: Caption: fastLTA_variable
: Data type: Datalist
: Listname: fastLTA_variable-list

Field name: fastLTA_warn
: Caption: fastLTA_warn

Field name: fastLTA_crit
: Caption: fastLTA_crit

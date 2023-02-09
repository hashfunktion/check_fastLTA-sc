#!/bin/bash

###############################################
#
# Icinga check-plugin for FastLTA Silent Cube
#
# Copyright (C) 2019 Jesse Reppin
# Contributor - log1
#
# Report bugs to:  https://github.com/hashfunktion/check_fastLTA-sc
#
# Created:	Version 0.1 - 2017-01-20 - Create check-plugins first version
# Updated:	Version 1.0 - 2017-01-27 - Puplication first stable version
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################

###############################################
#
## VARIABLES AND FUNCTIONS
#

## Check-Plugin Version
Version="1.0"

## EXIT CODES
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

## SNMP OIDs
# Headunit
statushead=".1.3.6.1.4.1.27417.2.1.0"
modereplica=".1.3.6.1.4.1.27417.2.2.0"
statusreplica=".1.3.6.1.4.1.27417.2.5.0"

#silentcube
statussc=".1.3.6.1.4.1.27417.3.1.1.7.0"
totalcapsc=".1.3.6.1.4.1.27417.3.2.0"
usedcapsc=".1.3.6.1.4.1.27417.3.3.0"

#Headunit Status
headok="60"
#workerDefect (-1),
#workerNotStarted (-2),
#workerBooting (2),
#workerRfRRunning (3),
#appBooting(10),
#appNoCubes(20),
#appVirginCubes(30),
#appRfrPossible(40),
#appRfrMixedCubes(45),
#appRfrActive(50),
#appReady(60),
#appMixedCubes(65),
#appReadOnly(70),
#appEnterpriseCubes(75),
#appEnterpriseMixedCubes(80)


#clean VARIABLES
res="0"
ressec="0"
usedpersc="0"

## HELP / USAGE
usage() {
	echo " Icinga check-plugin for FastLTA Silent Cube - Version $Version"
	echo ""
	echo " Note This program is distributed in the hope that it will be useful, "
	echo " but WITHOUT ANY WARRANTY; without even the implied warranty"
	echo " of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE"
	echo ""
	echo " Usage: check_fastLTA-sc.pl -H <HOSTNAME> -C <SNMP-Community> -o <check option> -w <warning threshold> -c <critical threshold> [ -h <for help/usage> ]"
	echo ""
	echo ""
	echo " 		-H		Host to check"
	echo "		-o		Define the part of the system you want to check."
	echo "					Existing check options:"
	echo "					headunit-status  	#Working state from the Headunit"
	echo "					replica-status 		#Checks if the replication works"
	echo "					sc-status					#Checks the Silent Cube status"
	echo "					sc-capusage				#Check the percentage usage of the silentcube"
	echo ""
	echo "		-w  	Warning threshold"
	echo "		-c  	Critical threshold"
	echo "		-h  	Show this page"
	echo ""
}

## data query
get_data () {
	res=$(snmpget -v 2c -c $commun $host $mib -Oqv)
	if [[ $? -ne 0 ]] ; then
		echo "Snmpget failed";
		exit 2
	fi
}

get_secdata () {
	ressec=$(snmpget -v 2c -c $commun $host $mib -Oqv)
	if [[ $? -ne 0 ]] ; then
		echo "Snmpget failed";
		exit 2
	fi
}

## options
while getopts "H:o:C:w:c:H:" opt
	do
		case $opt in
			H) host=$OPTARG;
			;;
			C) commun=$OPTARG;
			;;
			o) type=$OPTARG;
			;;
			w) warn=$OPTARG;
			;;
			c) crit=$OPTARG;
			;;
			h) usage
				exit;;
			*) usage
				exit;;
			esac
		done


###############################################
#
## check-plugin main part
#

case $type in
	headunit-status) mib=$statushead;
		get_data;
			if [[ $res -ne $headok ]]; then
				echo "CRITICAL - "$res"";
				exit $STATE_CRITICAL;
			else
				echo "OK - Headunit operating normal";
				exit $STATE_OK;
			fi;
		;;

	replica-status) mib=$statusreplica;
		get_data;
			if [[ $res -ne 1 ]]; then
				echo "CRITICAL - Replication is  NOT running or INCORRECT";
				exit $STATE_CRITICAL;
			else
				echo "OK - Replication is running normally";
				exit $STATE_OK;
			fi;
		;;

	sc-status) mib=$statussc;
		get_data;
			if [[ $res -eq 4 ]]; then
				echo "CRITICAL - SilentCube state: !-EMERGENCY-!";
				exit $STATE_CRITICAL;
			
				elif [[ $res -eq 3 ]]; then
					echo "CRITICAL - SilentCube state: !-DEGRADED-!";
					exit $STATE_CRITICAL;
			
				elif [[ $res -eq 2 ]]; then
					echo "CRITICAL - SilentCube state: !-DEFECTIV-!";
					exit $STATE_WARNING;
			
				elif [[ $res -eq 1 ]]; then
					echo "OK - SilentCube state: GOOD";
					exit $STATE_OK;
			fi;
		;;

	sc-capusage)
			mib=$totalcapsc;
				get_data;
			mib=$usedcapsc;
				get_secdata;
					let "usedpersc=(($ressec*100)/$res)"
				if [[ $usedpersc -ge $crit ]]; then
					echo "CRITICAL - SilentCube is "$usedpersc"% full!";
					exit $STATE_CRITICAL;
				
					elif [ $usedpersc -ge $warn ] &&  [ $usedpersc -lt $crit ]; then
						echo "WARNING - SilentCube is "$usedpersc"% full!";
						exit $STATE_WARNING;
					
						elif [[ $usedpersc -lt $warn ]]; then
							echo "OK - SilentCube is "$usedpersc"% full!";
							exit $STATE_OK;
					fi;
			;;
			
	*) echo "check-plugin syntax error -> check_fastLTA -h for help"; exit 2 ;;
esac
#

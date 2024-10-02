#!/bin/bash

###############################################
#
# Icinga check-plugin for FastLTA Silent Cube
#
# Copyright (C) 2024 Jesse Reppin - hashfunktion
# Contributor - log1-c
#
# Report bugs to:  https://github.com/hashfunktion/check_fastLTA-sc
#
# Created:	Version 0.1 - 2017-01-20 - Create check-plugins first version
# Updated:	Version 1.0 - 2017-01-27 - Puplication first stable version
# Updated:	Version 1.1 - 2023-02-09 - Added checks for fans, disks and psus
# Updated:      Version 1.2 - 2024-10-02 - Update MIB Codes and add multiple Check Outputs for headunit-status
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
Version="1.2"

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

#hardware
scips=".1.3.6.1.4.1.27417.3.1.1.6"
scnumdisks=".1.3.6.1.4.1.27417.3.1.1.12"
scnumokdisks=".1.3.6.1.4.1.27417.3.1.1.13"
scnumpsus=".1.3.6.1.4.1.27417.3.1.1.14"
scnumokpsus=".1.3.6.1.4.1.27417.3.1.1.15"
scnumfans=".1.3.6.1.4.1.27417.3.1.1.16"
scnumokfans=".1.3.6.1.4.1.27417.3.1.1.17"

#Headunit Status
headok="60"
#workerDefect (-1),
workerDefect="-1"
#workerNotStarted (-2),
workerNotStarted="-2"
#workerBooting (2),
workerBooting="2"
#workerRfRRunning (3),
workerRfRRunning="3"
#appBooting(10),
appBooting="10"
#appNoCubes(20),
appNoCubes="20"
#appVirginCubes(30),
appVirginCubes=30
#appRfrPossible(40),
appRfrPossible="40"
#appRfrMixedCubes(45),
appRfrMixedCubes="45"
#appRfrActive(50),
appRfrActive="50"
#appReady(60),
#appMixedCubes(65),
#appReadOnly(70),
appReadOnly="70"
#appEnterpriseCubes(75),
#appEnterpriseMixedCubes(80)


#clean VARIABLES
res="0"
ressec="0"
usedpersc="0"
output=""
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
        echo "          -H              Host to check"
        echo "          -o              Define the part of the system you want to check."
        echo "                          Existing check options:"
        echo "                          headunit-status         #Working state from the Headunit"
        echo "                          replica-status          #Checks if the replication works"
        echo "                          sc-status               #Checks the Silent Cube status"
        echo "                          sc-capusage             #Check the percentage usage of the silentcube"
	echo "                          sc-disks             	#Check the disks of the silentcube"
	echo "                          sc-fans             	#Check the fans of the silentcube"
	echo "                          sc-psus             	#Check the psus of the silentcube"
        echo ""
        echo "          -w      Warning threshold"
        echo "          -c      Critical threshold"
        echo "          -h      Show this page"
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
        if [[ $res -eq $headok ]]; then
                echo "OK - Headunit operating normal";
                exit $STATE_OK;
        elif [[ $res -eq $workerDefect ]]; then
            echo "CRITICAL - workerDefect";
            exit $STATE_CRITICAL;

        elif [[ $res -eq $workerNotStarted ]]; then
            echo "CRITICAL - Worker not started";
            exit $STATE_CRITICAL;

        elif [[ $res -eq $workerBooting ]]; then
            echo "WARNING - Worker booting";
            exit $STATE_WARNING;

        elif [[ $res -eq $workerRfRRunning ]]; then
            echo "OK - Worker ready for RFR running";
            exit $STATE_OK;

        elif [[ $res -eq $appBooting ]]; then
            echo "OK - Application booting";
            exit $STATE_OK;

        elif [[ $res -eq $appNoCubes ]]; then
            echo "CRITICAL - No cubes detected";
            exit $STATE_CRITICAL;

        elif [[ $res -eq $appVirginCubes ]]; then
            echo "WARNING - Virgin cubes available";
            exit $STATE_WARNING;

        elif [[ $res -eq $appRfrPossible ]]; then
            echo "INFO - RFR possible";
            exit $STATE_OK;

        elif [[ $res -eq $appRfrMixedCubes ]]; then
            echo "INFO - RFR with mixed cubes";
            exit $STATE_OK;

        elif [[ $res -eq $appRfrActive ]]; then
            echo "INFO - RFR active";
            exit $STATE_OK;

        elif [[ $res -eq $appReadOnly ]]; then
            echo "WARNING - Application in read-only mode";
            exit $STATE_WARNING;

        else
            echo "CRITICAL - Unknown status code: "$res"";
            exit $STATE_CRITICAL;
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
                echo "CRITICAL - SilentCube is "$usedpersc"% full!|usage=$usedpersc%;$warn;$crit";
                exit $STATE_CRITICAL;

                elif [ $usedpersc -ge $warn ] &&  [ $usedpersc -lt $crit ]; then
                echo "WARNING - SilentCube is "$usedpersc"% full!|usage=$usedpersc%;$warn;$crit";
                exit $STATE_WARNING;

                elif [[ $usedpersc -lt $warn ]]; then
                echo "OK - SilentCube is "$usedpersc"% full!|usage=$usedpersc%;$warn;$crit";
                exit $STATE_OK;
        fi;
        ;;

        sc-disks)
        mib=$scips;
        scnumberips=($(snmpwalk -v 2c -c $commun $host $mib -Oqv ));
        countscips=${#scnumberips[@]};

        for (( c=0; c<countscips; c++ ));
                do
                        mib="$scnumdisks.$c";
                        get_data;
                        numdisks=$res;
                        mib="$scnumokdisks.$c";
                        get_data;
                        numokdisks=$res;
                        if [[ $numokdisks -lt $numdisks  ]]; then
                                mib="$scips.$c";
                                get_data;
                                if [[ $output == "" ]];then
                                        output="IP($res): $numokdisks of $numdisks are OK!";
                                else
                                        output="$output\nIP($res): $numokdisks of $numdisks are OK!";
                                fi;
                                disks_failed=true;
                        fi;
                done
        if [ $disks_failed ]; then
                echo "At least one disk NOT OK!"
                if [[ $output != "" ]]; then 
					echo -e $output; 
				fi;
                exit $STATE_CRITICAL
         else
                echo "All disks OK!"
                if [[ $output != "" ]]; then 
					echo -e $output; 
				fi;
                exit $STATE_OK
        fi;
        ;;
		
		sc-psus)
        mib=$scips;
        scnumberips=($(snmpwalk -v 2c -c $commun $host $mib -Oqv ));
        countscips=${#scnumberips[@]};

        for (( c=0; c<countscips; c++ ));
                do
                        mib="$scnumpsus.$c";
                        get_data;
                        numpsus=$res;
                        mib="$scnumokpsus.$c";
                        get_data;
                        numokpsus=$res;
                        if [[ $numokpsus -lt $numpsus  ]]; then
                                mib="$scips.$c";
                                get_data;
                                if [[ $output == "" ]];then
                                        output="IP($res): $numokpsus of $numpsus are OK!";
                                else
                                        output="$output\nIP($res): $numokpsus of $numpsus are OK!";
                                fi;
                                psus_failed=true;
                        fi;
                done
        if [ $psus_failed ]; then
                echo "At least one PSU NOT OK!"
                if [[ $output != "" ]]; then 
					echo -e $output; 
				fi;
                exit $STATE_CRITICAL
         else
                echo "All PSUs OK!"
                if [[ $output != "" ]]; then 
					echo -e $output; 
				fi;
                exit $STATE_OK
        fi;
        ;;
		
		sc-fans)
        mib=$scips;
        scnumberips=($(snmpwalk -v 2c -c $commun $host $mib -Oqv ));
        countscips=${#scnumberips[@]};

        for (( c=0; c<countscips; c++ ));
                do
                        mib="$scnumfans.$c";
                        get_data;
                        numfans=$res;
                        mib="$scnumokfans.$c";
                        get_data;
                        numokfans=$res;
                        if [[ $numokfans -lt $numfans  ]]; then
                                mib="$scips.$c";
                                get_data;
                                if [[ $output == "" ]];then
                                        output="IP($res): $numokfans of $numfans are OK!";
                                else
                                        output="$output\nIP($res): $numokfans of $numfans are OK!";
                                fi;
                                fans_failed=true;
                        fi;
                done
        if [ $fans_failed ]; then
                echo "At least one fan NOT OK!"
                if [[ $output != "" ]]; then 
					echo -e $output; 
				fi;
                exit $STATE_CRITICAL
         else
                echo "All fans OK!"
                if [[ $output != "" ]]; then 
					echo -e $output; 
				fi;
                exit $STATE_OK
        fi;
        ;;
        *) echo "check-plugin syntax error -> check_fastLTA -h for help"; exit 2 ;;
esac
#

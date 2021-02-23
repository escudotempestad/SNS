#!/bin/bash
#The scope of this script is to backup and get a tech report from a SNS Firewall
#it is possible also to shutdown it
#in a next release, I will try to adapt it to be able to send a bunch of firewall in a csv file
#.
DATE=$(echo "[`date +%F" "%T`]")
function helping () {
echo " Usage: miscript.sh [options]

OPTIONS :
  -i ip_address
  -f firewall_name
  -t config | sysinfo | all 
  -d: delete all files in /tmp/ 
  -o : shutdown the firewall
  -z csv file

Version 0.1 - Alejandro Castano
-A technical port and a configuration backup will be created in this folder
"
exit
}
function creating_bk () {
	echo "$DATE Creating a config.na in $2"
	ssh admin@$1 "rm /tmp/config1.tgz" 2>&1
	ssh admin@$1 " encbackup -i /tmp/config1.tgz -o /tmp/$2.na -n all -t all"  2>&1
	echo " $DATE ---> Downloading the files from $1"
 	scp admin@$1:/tmp/$2.na ./  2>&1
	echo "$DATE Trying to download .pcap if any..."
 	scp admin@$1:/tmp/*pcap ./ > /dev/null 2>&1
}
function shutting_down () {
	echo "$DATE Shutting down the firewall"
	ssh admin@$1 "halt"
}
function creating_sysinfo () {
	echo "$DATE Creating a sysinfo in $1 called $2"
	ssh admin@$1 " sysinfo -a > /tmp/sysinfo.$2.txt " > /dev/null 2>&1
 	scp admin@$1:/tmp/sysinfo.$2.txt ./
}
function deleting_stuff () {
	echo "$DATE Removing obsolet files in $2"
	ssh admin@$1 "rm /tmp/*$2.txt"
	ssh admin@$1 "rm /tmp/*$2.na"
	}
if [ $# -eq 0 ]; then
	helping
fi
while getopts "odi:f:t:" opt; do
	case $opt in
		i)IPADDRESS=${OPTARG}
		;;
		f)FW=${OPTARG}
		;;
		t)TYPE=${OPTARG}
		;;
		d)DELETE=YES
		;;
		o)SHUTTINGDOWN=YES
		echo "Attention! The firewall will be shutted down after getting stuff.. you have 3 seconds to crtl+C"
		sleep 3
		;;
		\?) echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
		:) echo "Option: -$OPTARG requires an argument" >&2
		exit 1
		;;
	esac
done
if [ ! -z $DELETE ] && [ $DELETE == "YES" ]; then
	deleting_stuff $IPADDRESS $FW
fi
case $TYPE in
	config) creating_bk $IPADDRESS $FW
	;;
	sysinfo) creating_sysinfo $IPADDRESS $FW
	;;
	*) creating_bk $IPADDRESS $FW ;creating_sysinfo $IPADDRESS $FW 
	;;
esac
if [ ! -z  $SHUTTINGDOWN ] && [ $SHUTTINGDOWN == "YES" ]; then
	shutting_down $IPADDRESS $FW
fi

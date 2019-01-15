#!/bin/bash
#
# LSI megaraid_sas report
#
# by Karl Johnson -- karljohnson.it@gmail.com -- kj @ Freenode
#
# Version 1.4 - 2017/11/30
#
# You should add a cron every week for this, exemple:
# 0 7 * * 0 /bin/bash /opt/megeraid/lsireport.sh $email > /dev/null 2>&1
#
#

### Fetch information

CLIPATH="/opt/megaraid/"
DEVICE="/dev/sda"

if [ -f /opt/megaraid/storcli ]; then
	CLI="storcli"
elif [ -f /opt/megaraid/megacli ]; then
	CLI="megacli"
else
	echo "storcli or megacli not in /opt/megaraid, please check"
	exit 1
fi

if [ ! -f /usr/bin/mutt ]; then
	echo "mutt is not in /usr/bin, please check"
	exit 1
fi

if [ "$1" != "" ]; then
	EMAIL="$1"
else
	echo "please specify an email"
	exit 1
fi

if [ "$CLI" == "storcli" ]; then
	$CLIPATH$CLI /cALL show all > /tmp/AdpAllInfo.txt
elif [ "$CLI" == "megacli" ]; then
	$CLIPATH$CLI -AdpAllInfo -aALL > /tmp/AdpAllInfo.txt
fi

NUMARRAYS=$(grep "Virtual Drives" /tmp/AdpAllInfo.txt|awk '{print $4}')
LSILOG="/tmp/lsireport.txt"


### Report

echo -e "*****************************************************\n
LSI report for: $(hostname):\n" 3>&1 4>&2 >>$LSILOG 2>&1
if [ "$CLI" == "storcli" ]; then
	echo "Product:$(grep "Model = AVAGO\|Model = LSI" /tmp/AdpAllInfo.txt|cut -f2 -d"=")" 3>&1 4>&2 >>$LSILOG 2>&1
	echo "Firmware version: $(grep "Firmware Version" /tmp/AdpAllInfo.txt|awk '{print $4}')" 3>&1 4>&2 >>$LSILOG 2>&1
elif [ "$CLI" == "megacli" ]; then
	echo "Product: $(grep "Product Name" /tmp/AdpAllInfo.txt|awk '{print $4,$5,$6,$7,$8}')" 3>&1 4>&2 >>$LSILOG 2>&1
	echo "Firmware version: $(grep "FW Version" /tmp/AdpAllInfo.txt|awk '{print $4}')" 3>&1 4>&2 >>$LSILOG 2>&1
fi
echo -e "Driver version: $(/sbin/modinfo megaraid_sas|grep "version:"|grep -v 'srcversion\|rhelversion'|awk '{print $2}')\n" 3>&1 4>&2 >>$LSILOG 2>&1

echo -e "\nStatus of all arrays:\n" 3>&1 4>&2 >>$LSILOG 2>&1
if [ "$CLI" == "storcli" ]; then
	$CLIPATH$CLI /c0/vALL show|grep "DG\|GB\|TB" 3>&1 4>&2 >>$LSILOG 2>&1
elif [ "$CLI" == "megacli" ]; then
	i="0"
	while [ $i -lt "$NUMARRAYS" ]
	do
		echo " - Array #$i state is $($CLIPATH$CLI -LDInfo -L$i -aALL|grep State |awk '{print $3}')" 3>&1 4>&2 >>$LSILOG 2>&1
		echo " - Array #$i $($CLIPATH$CLI -LDInfo -L$i -aALL|grep 'Current Cache Policy')" 3>&1 4>&2 >>$LSILOG 2>&1
		i=$(($i+1))
	done
fi

echo -e "\n\nStatus of all device errors: 

Card $(grep 'Memory Correctable Errors' /tmp/AdpAllInfo.txt)
Card $(grep 'Memory Uncorrectable Errors' /tmp/AdpAllInfo.txt)" 3>&1 4>&2 >>$LSILOG 2>&1
if [ "$CLI" == "storcli" ]; then
	$CLIPATH$CLI /cALL/eALL/sALL show all|egrep "Error Count|Failure Count" 3>&1 4>&2 >>$LSILOG 2>&1
elif [ "$CLI" == "megacli" ]; then
	$CLIPATH$CLI -PDList -aALL|egrep "Error Count|Failure Count" 3>&1 4>&2 >>$LSILOG 2>&1
fi

if [ "$CLI" == "storcli" ]; then
	DEVICEIDS=$($CLIPATH$CLI /cALL/eALL/sALL show|grep -i 'HDD\|SSD'|awk '{print $2}'|sort -n)
	DISKTYPE=$($CLIPATH$CLI /cALL/eALL/sALL show|grep -i 'HDD\|SSD'|awk '{print $7}'|head -n 1)
elif [ "$CLI" == "megacli" ]; then
	DEVICEIDS=$($CLIPATH$CLI -PDList -aAll | egrep "Device Id:"|awk '{print $3}'|sort -n)
	DISKTYPE=$($CLIPATH$CLI -PDList -aAll|grep "PD Type"|awk '{print $3}'|head -n 1)
fi

echo -e "\n\nStatus of all $DISKTYPE disk SMART:\n" 3>&1 4>&2 >>$LSILOG 2>&1
while read line; do
   echo -e " - Drive $line:\n" 3>&1 4>&2 >>$LSILOG 2>&1
   if [ "$DISKTYPE" == "SATA" ]; then
   	        /usr/sbin/smartctl -a -d sat+megaraid,"$line" "$DEVICE"|egrep "Device Model:|SMART overall-health|Power_On_Hours|Temperature_Celsius|Raw_Read_Error_Rate|Reallocated_Event_Count|Current_Pending_Sector|Offline_Uncorrectable|UDMA_CRC_Error_Count|Multi_Zone_Error_Rate" 3>&1 4>&2 >>$LSILOG 2>&1
   elif [ "$DISKTYPE" == "SAS" ]; then
	        /usr/sbin/smartctl -a -d megaraid,"$line" "$DEVICE"|egrep "Product:|SMART Health|Current Drive Temperature|Elements in grown defect|Errors Corrected|algorithm|read:|write:|verify:|Non-medium" 3>&1 4>&2 >>$LSILOG 2>&1
   fi
   echo -e "\n" 3>&1 4>&2 >>$LSILOG 2>&1
done <<< "$DEVICEIDS"


### Dumping last 1000 lines of device events

echo -e "Finaly, last 1000 lines of the event log for verification:\n" 3>&1 4>&2 >>$LSILOG 2>&1
if [ "$CLI" == "storcli" ]; then
	$CLIPATH$CLI /cALL show events|tail -n1000 3>&1 4>&2 >>$LSILOG 2>&1
elif [ "$CLI" == "megacli" ]; then
	$CLIPATH$CLI -AdpEventLog -GetEvents -f /dev/stdout -aALL|tail -n1000 3>&1 4>&2 >>$LSILOG 2>&1
fi

echo -e "Here's the full weekly LSI report for $(hostname)" | /usr/bin/mutt -a "$LSILOG" -s "LSI report for: $(hostname)" -- "$EMAIL"


### Cleanup
rm -I /tmp/AdpAllInfo.txt /root/sent $LSILOG
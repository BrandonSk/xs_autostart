#!/bin/bash

# Script for autostarting XenServer Virtual Machines
#
# 2018 Created by Branislav Susila
# Available at: https://github.com/BrandonSk/xs_autostart
# Distributed under MIT license

LF=/var/log/autostart.log
[ -f "${LF}" ] && rm -f "${LF}"

# Following will repair LUN storage repository provided by ZFS in one of the VMs
# Script is run from rc.local few minutes after boot to allow VM to start
echo "Repairing local ZFS storage repository..." >> "${LF}"
xe pbd-plug uuid=1ab4b2a9-372e-902b-1c1f-45334176c7f6 2>&1 | tee -a "${LF}"

# let SR to settle
sleep 10

# Function to start VM
f_start_vm() {
	# Starts xen VM and then waits specified time
	# $1 -> not used, comes as group identifier
	# $2 -> uuid of the vm to start
	# $3 -> sleep time
	# $4 -> power state of the VM
	# $5 -> name of the VM enclosed in '' where each space was replaces with ##
	
	[ "$#" -lt 5 ] && return

	# We only attempt to start machines which are not running
	if [ "${4}" != "running" ]; then
		echo "Starting VM named '${5//\#\#/ }' at $(date)" >> "${LF}"
		xe vm-start vm="${5//\#\#/ }" 2>&1 | tee -a "${LF}"
		sleep $3
	fi
}

VMlist="$(xe vm-list | grep uuid | awk -F': ' '{ print $2 }')"

AS_List=""
for VM in ${VMlist}
do
	AS="" && AS_G="" && AS_T=""
	AS="$(xe vm-param-get \
		uuid=${VM} \
		param-name=other-config \
		param-key=XenCenter.CustomFields.bs_autostart 2>/dev/null)"
	# Only continue if autostart is enabled
	if [ "${AS}" == "1" ]; then
		AS_G="$(xe vm-param-get \
			uuid=${VM} \
			param-name=other-config \
			param-key=XenCenter.CustomFields.bs_autostart_group 2>/dev/null)"
		case "${AS_G}" in
			''|*[!0-9]*)
				echo "Group not a number (${AS_G})." >> "${LF}"
				AS_G=""
				;;
			*)
				AS_T="$(xe vm-param-get \
					uuid=${VM} \
					param-name=other-config \
					param-key=XenCenter.CustomFields.bs_autostart_timeout 2>/dev/null)"
				case "${AS_T}" in
					''|*[!0-9]*)
						echo "Next VM start after is not a number (${AS_T}). Using 0." >> "${LF}"
						AS_T=0
						;;
					*)
						echo "Next VM will start after ${AS_T} seconds." >> "${LF}"
						;;
				esac
				;;
		esac
		AS_N="$(xe vm-list uuid=$VM | grep name-label | awk -F': ' '{ print $2 }')"
		AS_PS="$(xe vm-list uuid=$VM | grep power-state | awk -F': ' '{ print $2 }')"
		[ ! -z "${AS_G}" ] && AS_List="${AS_List}"$'\n'"${AS_G} ${VM} ${AS_T} ${AS_PS} ${AS_N// /\#\#}"
	fi
done

while read i
do
	f_start_vm $i
done < <(echo "${AS_List}" | sort -bn)

echo "Finished" >> "${LF}"

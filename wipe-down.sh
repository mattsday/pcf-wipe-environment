#!/bin/bash
# Input checking
if [ -z ${PAS_ADMIN_USER} ]; then echo NO PAS_ADMIN_USER; exit 1; fi
if [ -z ${PAS_ADMIN_PW} ]; then echo NO PAS_ADMIN_PW; exit 1; fi
if [ -z ${PAS_SAFE_ORGS} ]; then echo NO PAS_SAFE_ORGS; exit 1; fi
if [ -z ${PAS_SAFE_SPACES} ]; then echo NO PAS_SAFE_SPACES; exit 1; fi
if [ -z ${PAS_API_ADDRESS} ]; then echo NO PAS_API_ADDRESS; exit 1; fi

# Login to CF in the system org/space
cf login -a ${PAS_API_ADDRESS} -u ${PAS_ADMIN_USER} -p ${PAS_ADMIN_PW} -o system -s system 

CF_ORGS=$(cf orgs | tail -n +4)
PAS_SAFE_ORGS=$(echo ${PAS_SAFE_ORGS} | sed 's/,/ /g')
PAS_SAFE_SPACES=$(echo ${PAS_SAFE_SPACES} | sed 's/,/ /g')


for org in ${CF_ORGS}; do
	# NEVER wipe the system org, ignore config
    if [ "{$org}" = "system" ]; then
        continue
    fi
	if [[ ${PAS_SAFE_ORGS} =~ (^|[[:space:]])${org}($|[[:space:]]) ]]; then
		echo $org is safe
		continue;
	fi
	cf target -o $org >/dev/null 2>&1
    ORG_SPACES=$(cf spaces | tail -n +4)
    for space in $ORG_SPACES; do
		if [[ ${PAS_SAFE_SPACES} =~ (^|[[:space:]])${space}($|[[:space:]]) ]]; then
			echo $space in $org is safe
			continue;
		fi
        cf target -o $org -s $space >/dev/null 2>&1
        CF_APPS=$(cf apps | tail -n +5 | awk '{print $1}')
        echo Deleting all apps in org $org space $space
        for app in $CF_APPS; do
			case $app in
				*-keep)
					;;
				*)
					cf delete -f $app
					;;
			esac
        done
		echo Deleting all services in org $org space $space
		CF_SERVICES=$(cf services | tail -n +5 | awk '{print $1}')
		for service in $CF_SERVICES; do
			case $service in
				*-keep)
					;;
				*)
					cf delete-service -f $service
					;;
			esac
		done
		echo Clearing up routes
		cf routes | tail -n +4 | while read -r line; do
			ROUTE_APP=$(echo $line | awk '{print $4}')
			if [ -z "$ROUTE_APP" ]; then 
				cf delete-route -f --hostname $(echo $line | awk '{ print $2 }') $(echo $line | awk '{ print $3 }')
			fi
		done
    done
done

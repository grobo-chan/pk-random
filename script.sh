#!/bin/bash

BIAS="false"
PK_TOKEN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Tiny script to pick a random headmate from PluralKit"
            echo "Usage: $0 [-b|--bias] [-t|--token TOKEN]"
            echo
            echo "In bias mode the headmate's who front less are more likely to be picked."
            echo "This program will require your PK Token. These are used to send requests to the PK API to fetch members and front history."
            echo "The token is NOT being sent anywhere else and is only used for the purpose of data fetching."
            echo "If token is not supplied via --token, the program will ask for one."
            exit 0
            ;;
        -b|--bias)
            BIAS="true"
            shift
            ;;
        -t|--token)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: --token requires an argument" 1>&2
                exit 1
            fi
            PK_TOKEN="$2"
            shift 2
            ;;
        *)
            echo "Unknown Option: $1" 1>&2
            exit 1
            ;;
    esac
done

if [[ -z "$PK_TOKEN" || "$PK_TOKEN" == -* ]]; then
    read -r -p "Enter your PK Token: " PK_TOKEN
fi

MEMBERS="$(curl -s -H "Authorization: $PK_TOKEN" https://api.pluralkit.me/v2/systems/@me/members | jq 'map(select(.privacy.visibility == "public"))' )"
COUNT=$(echo "$MEMBERS" | jq 'length')

if [[ "$BIAS" == "true" ]]; then
    # Get past 100 swicthes
    DATA="$(curl -s -H "Authorization: $PK_TOKEN" https://api.pluralkit.me/v2/systems/@me/switches | jq -c .[])"
    PREV_TIMESTAMP=$(date +%s)
    echo "$DATA" | while read i; do
        # jq doesn't support microseconds so we cut them out with crazy ass regex
        # We also need to convert the timestamp from ISO-8601 to Unix Timestamps
        CURR_TIMESTAMP=$(echo "$i" | jq '.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601')

        # Calculate front time
        # For first member of array (fronter) is TIME_NOW - TIMESTAMP_IN_JSON
        # For rest it is PREV_TIMESTAMP - CURR_TIMESTAMP
        DELTA=$((PREV_TIMESTAMP - CURR_TIMESTAMP))
        days=$(( DELTA / 86400 ))
        hours=$(( (DELTA % 86400) / 3600 ))
        minutes=$(( (DELTA % 3600) / 60 ))
        seconds=$(( DELTA % 60 ))

        echo "Front time for members $(echo "$i" | jq -c .members) is ${days}d ${hours}h ${minutes}m ${seconds}s"

        # Set the PREV_TIMESTAMP for next iteration
        PREV_TIMESTAMP="$CURR_TIMESTAMP"
    done
else
    # Pick a random member
    rand_idx=$(( RANDOM % COUNT ))
    HEADMATE=$(echo "$MEMBERS" | jq --argjson idx "$rand_idx" '.[$idx].display_name')
    echo "The headmate selected is: $HEADMATE"
fi

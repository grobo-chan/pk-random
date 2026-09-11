#!/bin/bash

BIAS="false"
PK_TOKEN=""

# In bias mode: the headmate's who front less are more favoured
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0 [-b|--bias] [-t|--token TOKEN]"
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
    SWITCHES="$(curl -s -H "Authorization: $PK_TOKEN" https://api.pluralkit.me/v2/systems/@me/switches | jq .)"
    echo "$SWITCHES"
else
    # Pick a random member
    rand_idx=$(( RANDOM % COUNT ))
    HEADMATE=$(echo "$MEMBERS" | jq --argjson idx "$rand_idx" '.[$idx].display_name')
    echo "The headmate selected is: $HEADMATE"
fi

#!/bin/bash

BIAS="false"
PK_TOKEN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            echo "Tiny script to pick a random headmate from PluralKit"
            echo "Usage: $0 [-b|--bias] [-t|--token TOKEN]"
            echo
            echo "In --bias mode the headmate's who front less are more likely to be picked."
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

get_headmate_name() {
    echo "$1" | jq '.display_name // .name'
}

if [[ "$BIAS" == "true" ]]; then
    declare -A MEMBER_TIMES
    # Get every member and set their front time to 0
    while read i; do
        MEMBER_TIMES["$i"]=0
    done < <(echo "$MEMBERS" | jq -c .[].id)

    # Get past 100 swicthes
    DATA="$(curl -s -H "Authorization: $PK_TOKEN" https://api.pluralkit.me/v2/systems/@me/switches | jq -c .[])"
    PREV_TIMESTAMP=$(date +%s)

    while read i; do
        # jq doesn't support microseconds so we cut them out with crazy ass regex
        # We also need to convert the timestamp from ISO-8601 to Unix Timestamps
        CURR_TIMESTAMP=$(echo "$i" | jq '.timestamp | sub("\\.[0-9]+Z$"; "Z") | fromdateiso8601')

        # Calculate front time
        # For first member of array (fronter) is TIME_NOW - TIMESTAMP_IN_JSON
        # For rest it is PREV_TIMESTAMP - CURR_TIMESTAMP
        DELTA=$((PREV_TIMESTAMP - CURR_TIMESTAMP))

        # Make a bash Associative Array in the format of "pk_member_id": "front_time"
        while read -r m; do
            MEMBER_TIMES["$m"]=$((${MEMBER_TIMES["$m"]:-0} + DELTA))
        done < <(echo "$i" | jq '.members[]')

        # Set the PREV_TIMESTAMP for next iteration
        PREV_TIMESTAMP="$CURR_TIMESTAMP"
    done < <(echo "$DATA")

    # Scary ass awk script because awk lets us do weighted random
    ID=$(
        for k in "${!MEMBER_TIMES[@]}"; do
            echo "$k ${MEMBER_TIMES[$k]}"
        done | awk '
            {
                keys[NR] = $1;
                vals[NR] = $2;
            }
            END {
                n = NR;
                if (n == 0) exit;

                # So, for our weighted random, the weights are determined by 1-PERCENTILE
                # Where PERCENTILE = (HEADMATE_FRONT_TIME - MIN_FRONT_TIME) / (MAX_FRONT_TIME - MIN_FRONT_TIME)

                # Get MIN_FRONT_TIME & MAX_FRONT_TIME
                min_v = vals[1];
                max_v = vals[1];
                for (i = 2; i <= n; i++) {
                    if (vals[i] < min_v) min_v = vals[i];
                    if (vals[i] > max_v) max_v = vals[i];
                }

                range = max_v - min_v;
                srand();
                total_weight = 0;

                # Calculate the weights (1 - PERCENTILE)
                for (i = 1; i <= n; i++) {
                    if (range == 0) {
                        weights[i] = 1; # All values are identical
                    } else {
                        weights[i] = 1.0 - ((vals[i] - min_v) / range);
                    }
                    total_weight += weights[i];
                }

                # Let the randomizer do its thing
                r = rand() * total_weight;
                sum = 0;
                for (i = 1; i <= n; i++) {
                    sum += weights[i];
                    if (r <= sum) {
                        print keys[i]; # This is the Member ID in PK
                        exit;
                    }
                }

                print keys[n];
            }
        '
    )

    # Filter the JSON by Member ID and get the Display Name
    HEADMATE=$(echo "$MEMBERS" | jq --argjson id "$ID" '.[] | select(.id == $id)')
    NAME=$(get_headmate_name "$HEADMATE")
    echo "The headmate selected is: $NAME"
    echo "Their PK ID is: $ID"
else
    # Pick a random member
    rand_idx=$(( RANDOM % COUNT ))
    HEADMATE=$(echo "$MEMBERS" | jq --argjson idx "$rand_idx" '.[$idx]')
    NAME=$(get_headmate_name "$HEADMATE")
    ID=$(echo "$HEADMATE" | jq .id)
    echo "The headmate selected is: $NAME"
    echo "Their PK ID is: $ID"
fi

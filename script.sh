#!/bin/bash

BIAS="false"
PK_TOKEN=""

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

echo "Bias Mode: $BIAS"
echo "PK Token: $PK_TOKEN"

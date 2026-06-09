#!/bin/bash

# INPUT_FILE="$1"
# OUTPUT_FILE="$2"
# NEEDLE="${3:-Deprecation Notice: }"
# EXCLUDE_STRING1="${4:-Automatic TCA migration done during bootstrap. Please adapt TCA accordingly}"
# EXCLUDE_STRING2="${5:-e73f1ece5087b8a5ae33998952202202}"

NEEDLE="Deprecation Notice: "
## Taken from the deprecation log in 12 LTS there might be an other string in other TYPO3 Version
EXCLUDE_STRING1="Automatic TCA migration done during bootstrap. Please adapt TCA accordingly"
## e73f1ece5087b8a5ae33998952202202 random Hash as Placeholder and to make sure it's not in the Log File
EXCLUDE_STRING2="e73f1ece5087b8a5ae33998952202203"

USAGE_MESSAGE="
Usage: $0 --input INPUT_FILE --output OUTPUT_FILE [--needle 'MY NEEDLE'] [--exclude1 'MY STR1'] [--exclude2 'MY STR2']

Description:
  This script filters a log file by extracting lines that contain a specific 'needle' string,
  and excludes lines matching one or two optional exclusion patterns.

Options:
  -h, --help           Show this help message and exit

  --input FILE         [Required] Path to the input log file to be processed.
  --output FILE        [Required] Path to the output file where filtered results will be saved.

  --needle STRING      [Optional] A string used to split each line. The script extracts the part
                       after this needle. If the needle is not found in a line, the entire line is kept.
                       Default: \"Deprecation Notice: \"

  --exclude1 STRING    [Optional] A string pattern to exclude from the output.
                       Lines that match this pattern will be removed.
                       Default: \"Automatic TCA migration done during bootstrap. Please adapt TCA accordingly\"

  --exclude2 STRING    [Optional] A second string pattern to exclude from the output.
                       Default: \"e73f1ece5087b8a5ae33998952202202\"
"

for arg in "$@"; do
  case $arg in
    -h|--help)
      echo -e "$USAGE_MESSAGE"
      exit 0
      ;;
  esac
done

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --input)
            if [[ -n "$2" && "$2" != --* ]]; then
                INPUT_FILE="$2"; shift
            else
                echo "Error: --input requires a non-empty value."; echo -e "$USAGE_MESSAGE"; exit 1
            fi
            ;;
        --output)
            if [[ -n "$2" && "$2" != --* ]]; then
                OUTPUT_FILE="$2"; shift
            else
                echo "Error: --output requires a non-empty value."; echo -e "$USAGE_MESSAGE"; exit 1
            fi
            ;;
        --needle)
            if [[ -n "$2" && "$2" != --* ]]; then
                NEEDLE="$2"; shift
            fi
            ;; # Optional, so no error if empty
        --exclude1)
            if [[ -n "$2" && "$2" != --* ]]; then
                EXCLUDE_STRING1="$2"; shift
            fi
            ;; # Optional, so no error if empty
        --exclude2)
            if [[ -n "$2" && "$2" != --* ]]; then
                EXCLUDE_STRING2="$2"; shift
            fi
            ;; # Optional, so no error if empty
        *)
            echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo " Error: --input and --output parameters are required!!!"
    echo -e "$USAGE_MESSAGE"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo " Error: Input file not found at '$INPUT_FILE'"
    exit 1
fi

echo "Processing '$INPUT_FILE'..."
echo "Using every Line with needle: '$NEEDLE'..."
echo "Excluding Lines with strings: '$EXCLUDE_STRING1' && '$EXCLUDE_STRING2'..."

awk -F"$NEEDLE" '{if (NF>1) print $2; else print $0}' "$INPUT_FILE" | grep -Ev "^($EXCLUDE_STRING1|$EXCLUDE_STRING2)" | sort |  uniq > "$OUTPUT_FILE"

echo "Done! Filtered log has been saved to '$OUTPUT_FILE'"

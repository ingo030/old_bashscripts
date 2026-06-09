#!/bin/bash

#############################################
#############################################
### Setup the TYPO3
### Download and Import Database
### Download, Check and Import Fileadmin
#############################################
#############################################
TYPO3_BRANCH=""
BASE_DOMAIN=""
SUB_DOMAIN=""
SSH_USER=""
LIVE_SERVER_PATH=""
DB_DUMP_NAME=""
FILEADMIN_DUMP_NAME=""

CURRENTFOLDER="$(basename "$PWD")"
PREFIXFILESFOLDER="files."
NEWFOLDER="$PREFIXFILESFOLDER$CURRENTFOLDER"

USAGE_MESSAGE="
 Usage: $0 --getDB yes|no --getFileadmin yes|no

 Description:
   This script sets up TYPO3 including loading the Database and/or Fileadmin
   from the current LIVE Server, if necessary.

 Preparation:
   If a project with the same name already exists, please delete it first:
     ddev delete --omit-snapshot local-fuehrungs-akademie

 Options:
   -h, --help             Show this help message and exit

   --getDB STRING         [Required] Specify whether to load the Database from the current LIVE Server (yes or no).
                          If 'no' and the file ../$NEWFOLDER/$DB_DUMP_NAME is missing, it will be loaded anyway.
                          If 'yes' and the file exists, it will be replaced.

   --getFileadmin STRING  [Required] Specify whether to load Fileadmin from the current LIVE Server (yes or no).
                          If 'no' and the file ../$NEWFOLDER/$FILEADMIN_DUMP_NAME is missing, it will be loaded anyway.
                          If 'yes' and the file exists, it will be replaced.
"

# Parse help
for arg in "$@"; do
  case $arg in
    -h|--help)
      echo -e "$USAGE_MESSAGE"
      exit 0
      ;;
  esac
done

# Parse parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --getDB)
            if [[ -n "$2" && "$2" != --* ]]; then
                if [[ "$2" == "yes" || "$2" == "no" ]]; then
                    GET_DB="$2"
                else
                    echo " Error: --getDB parameter must be 'yes' or 'no'."; echo -e "$USAGE_MESSAGE"; exit 1
                fi
                shift
            else
                echo " Error: --getDB parameter must be 'yes' or 'no'."; echo -e "$USAGE_MESSAGE"; exit 1
            fi
            ;;
        --getFileadmin)
            if [[ -n "$2" && "$2" != --* ]]; then
                if [[ "$2" == "yes" || "$2" == "no" ]]; then
                    GET_FILEADMIN="$2"
                else
                    echo " Error: --getFileadmin parameter must be 'yes' or 'no'."; echo -e "$USAGE_MESSAGE"; exit 1
                fi
                shift
            else
                echo " Error: --getFileadmin parameter must be 'yes' or 'no'."; echo -e "$USAGE_MESSAGE"; exit 1
            fi
            ;;
        *)
            echo " Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Check if parameters are set
if [ -z "$GET_DB" ] || [ -z "$GET_FILEADMIN" ]; then
    echo " Error: both --getDB and --getFileadmin parameters are required!!!"
    echo -e "$USAGE_MESSAGE"
    exit 1
fi

# create directory and prefix with "$PREFIXFILESFOLDER"
mkdir -p "../$NEWFOLDER"

# load DB Dump if needed
if [[ "$GET_DB" == "no" && ! -f "../$NEWFOLDER/$DB_DUMP_NAME" ]]; then
    echo " no Database available at ../$NEWFOLDER/$DB_DUMP_NAME"
    echo " load Database: scp -C $SSH_USER:$LIVE_SERVER_PATH/$DB_DUMP_NAME ../$NEWFOLDER/$DB_DUMP_NAME"
    scp -C $SSH_USER:$LIVE_SERVER_PATH/$DB_DUMP_NAME ../$NEWFOLDER/$DB_DUMP_NAME
fi

# load DB Dump if wanted
if [[ "$GET_DB" == "yes" ]]; then
    if [ -f "../$NEWFOLDER/$DB_DUMP_NAME" ]; then
      echo " move old Database from ../$NEWFOLDER/$DB_DUMP_NAME to ../$NEWFOLDER/backup_$DB_DUMP_NAME"
       mv ../$NEWFOLDER/$DB_DUMP_NAME ../$NEWFOLDER/backup_$DB_DUMP_NAME
    fi
    echo " load Database: scp -C $SSH_USER:$LIVE_SERVER_PATH/$DB_DUMP_NAME ../$NEWFOLDER/$DB_DUMP_NAME"
    scp -C $SSH_USER:$LIVE_SERVER_PATH/$DB_DUMP_NAME ../$NEWFOLDER/$DB_DUMP_NAME
fi

# load Fileadmin Dump if needed
if [[ "$GET_FILEADMIN" == "no" && ! -f "../$NEWFOLDER/$FILEADMIN_DUMP_NAME" ]]; then
    echo " no Fileadmin Dump available at ../$NEWFOLDER/$FILEADMIN_DUMP_NAME"
    echo " load Fileadmin: scp -C $SSH_USER:$LIVE_SERVER_PATH/$FILEADMIN_DUMP_NAME ../$NEWFOLDER/$FILEADMIN_DUMP_NAME"
    scp -C $SSH_USER:$LIVE_SERVER_PATH/$FILEADMIN_DUMP_NAME ../$NEWFOLDER/$FILEADMIN_DUMP_NAME
fi

# load Fileadmin Dump if wanted
if [[ "$GET_FILEADMIN" == "yes" ]]; then
    if [ -f "../$NEWFOLDER/$FILEADMIN_DUMP_NAME" ]; then
          echo " move old Fileadmin from ../$NEWFOLDER/$FILEADMIN_DUMP_NAME to ../$NEWFOLDER/backup_$FILEADMIN_DUMP_NAME"
           mv ../$NEWFOLDER/$FILEADMIN_DUMP_NAME ../$NEWFOLDER/backup_$FILEADMIN_DUMP_NAME
        fi
    echo " load Fileadmin: scp -C $SSH_USER:$LIVE_SERVER_PATH/$FILEADMIN_DUMP_NAME ../$NEWFOLDER/$FILEADMIN_DUMP_NAME"
    scp -C $SSH_USER:$LIVE_SERVER_PATH/$FILEADMIN_DUMP_NAME ../$NEWFOLDER/$FILEADMIN_DUMP_NAME
fi

# checkout branch $TYPO3_BRANCH
git checkout $TYPO3_BRANCH
if [ "origin/$(git branch --show-current)" != "$TYPO3_BRANCH" ]; then
    git checkout "$TYPO3_BRANCH"
fi

#check Fileadmin Dump
echo " checking Fileadmin Archiv might take a while..."
if tar -tzf "../$NEWFOLDER/$FILEADMIN_DUMP_NAME" &>/dev/null; then
    echo " Archive is valid"
else
    echo " Error: Fileadmin Archive invalid or corrupted"
    exit 1
fi

# remove old project
# echo " remove old projects ddev delete --omit-snapshot local-fuehrungs-akademie"
# ddev delete --omit-snapshot local-fuehrungs-akademie

# start and install
echo " ... ddev start && ddev auth ssh && ddev composer install --no-scripts"
ddev start && ddev auth ssh && ddev composer install --no-scripts

# import db
echo " ... import Database: ddev import-db --file=../$NEWFOLDER/$DB_DUMP_NAME"
ddev import-db --file=../$NEWFOLDER/$DB_DUMP_NAME

# import Fileadmin
echo "... import Fileadmin Dump: tar xzf ../$NEWFOLDER/$FILEADMIN_DUMP_NAME -C public/fileadmin"
mkdir -p public/fileadmin && tar xzf ../$NEWFOLDER/$FILEADMIN_DUMP_NAME -C public/fileadmin

# copy .env.example
cp .env.example .env

# replace encryption key, TYPO3_Context and Base Domains
NEW_TYPO3_SYS_ENCRYPTIONKEY=$(openssl rand -hex 48)
sed -i "s|^TYPO3_SYS_ENCRYPTIONKEY=.*|TYPO3_SYS_ENCRYPTIONKEY='$NEW_TYPO3_SYS_ENCRYPTIONKEY'|" .env
sed -i "s|^TYPO3_CONTEXT=.*|TYPO3_CONTEXT='Development/Local/DDev'|" .env
sed -i "s|^BASE_DOMAIN_MAIN=.*|BASE_DOMAIN_MAIN='$BASE_DOMAIN'|" .env
sed -i "s|^BASE_DOMAIN_SUBDOMAIN=.*|BASE_DOMAIN_SUBDOMAIN='$SUB_DOMAIN.$BASE_DOMAIN'|" .env

echo " ... ddev composer install"
ddev composer install

echo " ... make Database compare"
ddev typo3 database:updateschema '*.add,*.change' -v

echo " ... flush cache"
ddev typo3 cache:flush

echo " ... ddev add-on get ddev/ddev-phpmyadmin"
ddev add-on get ddev/ddev-phpmyadmin

ddev describe
